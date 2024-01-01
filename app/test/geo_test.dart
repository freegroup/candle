import 'package:candle/models/route.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/geocoding_osm.dart';
import 'package:candle/utils/geo.dart';
import 'package:test/test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  GeocodingService geo = OSMGeocodingService();
  //GeocodingService geo = GoogleMapsGeocodingService();
  test('Geolocation address lookup', () async {
    LatLng start = LatLng(49.459669845037425, 8.603467947203);
    LatLng end = LatLng(49.456013764674395, 8.595982340735398);
    Route? route = await geo.getPedestrianRoute(start, end);
    print(route?.toGPX());
    // You can add more specific tests here, like checking if the address contains certain strings
  });
}
