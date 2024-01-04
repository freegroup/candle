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
