import 'dart:math' as math;
import 'package:candle/models/location.dart' as model;

double radians(double degrees) {
  return degrees * (math.pi / 180);
}

double degrees(double radians) {
  return radians * (180 / math.pi);
}

int calculateNorthBearing({required model.Location poiBase, required model.Location poiTarget}) {
  // Current position
  double lat1 = poiBase.lat;
  double lon1 = poiBase.lon;

  // Target position
  double lat2 = poiTarget.lat;
  double lon2 = poiTarget.lon;

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

double calculateDistance({required model.Location poiBase, required model.Location poiTarget}) {
  // Convert degrees to radians
  double radians(double degrees) => degrees * (math.pi / 180);

  // Earth's radius in meters
  const double earthRadius = 6371000;

  // Current position in radians
  double lat1 = radians(poiBase.lat);
  double lon1 = radians(poiBase.lon);

  // Target position in radians
  double lat2 = radians(poiTarget.lat);
  double lon2 = radians(poiTarget.lon);

  // Differences in coordinates
  double deltaLat = lat2 - lat1;
  double deltaLon = lon2 - lon1;

  // Haversine formula
  double a = math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);

  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  // Distance in meters
  return earthRadius * c;
}
