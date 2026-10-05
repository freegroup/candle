import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

double radians(double degrees) {
  return degrees * (math.pi / 180);
}

double degrees(double radians) {
  return radians * (180 / math.pi);
}

int calculateNorthBearing(LatLng coord1, LatLng coord2) {
  // Current position
  double lat1 = coord1.latitude;
  double lon1 = coord1.longitude;

  // Target position
  double lat2 = coord2.latitude;
  double lon2 = coord2.longitude;

  // Difference in longitude
  double deltaLon = radians(lon2 - lon1);

  // Convert to radians
  lat1 = radians(lat1);
  lat2 = radians(lat2);

  // Calculate the azimuth
  double x = math.sin(deltaLon) * math.cos(lat2);
  double y = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

  // Convert from radians to degrees
  double bearing = degrees(math.atan2(x, y));
  bearing = (bearing + 360) % 360; // Normalize to 0-360 degrees
  return bearing.toInt();
}

double calculateDistance(LatLng geo1, LatLng geo2) {
  const Distance distance = Distance();
  return distance(geo1, geo2);
}

double distanceToSegment({required LatLng point, required LatLng start, required LatLng end}) {
  // Check if start and end points are the same
  if (start.latitude == end.latitude && start.longitude == end.longitude) {
    double oneMeterInDegreesLat = 1 / 111000; // Approximation
    double oneMeterInDegreesLon = 1 / (111000 * math.cos(start.latitude * pi / 180));
    // New coordinates, adjusted by approx. 1 meter
    start = LatLng(
        start.latitude + oneMeterInDegreesLat, // Adjust latitude by 1 meter
        start.longitude + oneMeterInDegreesLon // Adjust longitude by 1 meter
        );
  }

  // Calculate U
  double u = ((point.longitude - start.longitude) * (end.longitude - start.longitude)) +
      ((point.latitude - start.latitude) * (end.latitude - start.latitude));

  double uDenom = math.pow(end.longitude - start.longitude, 2) +
      math.pow(end.latitude - start.latitude, 2).toDouble();
  u /= uDenom;

  var factor = u;

  if (factor < 0) {
    return calculateDistance(point, start); // Beyond the segmentStart end of the segment
  } else if (factor > 1) {
    return calculateDistance(point, end); // Beyond the segmentEnd end of the segment
  }

  LatLng projection = LatLng(
    start.latitude + factor * (end.latitude - start.latitude),
    start.longitude + factor * (end.longitude - start.longitude),
  );

  return calculateDistance(point, projection);
}

/// Smallest angle between two compass directions (0..180).
num angleBetween(num a, num b) {
  final difference = (a - b).abs() % 360;
  return difference > 180 ? 360 - difference : difference;
}

/// A compass direction counts as reached within ±[snapRange]° around it.
const snapRange = 10;

/// The compass direction (0, 45, … 315) within ±[snapRange]° of [heading], or null
/// between two directions.
int? snapToDirection(num heading) {
  final nearest = (heading / 45).round() % 8 * 45;
  return angleBetween(heading, nearest) <= snapRange ? nearest : null;
}

/// Whether [point] lies inside the closed [polygon] shrunk by [inset] meters, i.e.
/// inside and at least [inset] meters away from each of its edges (ray casting; fine for small areas like buildings,
/// where latitude and longitude act as plane coordinates).
bool isInsidePolygon(LatLng point, List<LatLng> polygon, {double inset = 0}) {
  for (var i = 1; i < polygon.length; i++) {
    if (distanceToSegment(point: point, start: polygon[i - 1], end: polygon[i]) < inset) {
      return false;
    }
  }
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
        point.longitude <
            (b.longitude - a.longitude) * (point.latitude - a.latitude) / (b.latitude - a.latitude) +
                a.longitude) {
      inside = !inside;
    }
  }
  return inside;
}
