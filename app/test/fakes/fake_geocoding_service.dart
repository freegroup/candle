import 'dart:ui';

import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding.dart';
import 'package:latlong2/latlong.dart';

class FakeGeocodingService implements GeocodingService {
  LocationAddress? address;

  @override
  Future<LocationAddress?> getGeolocationAddress(LatLng coord) async => address;

  @override
  Future<List<LocationAddress>> searchNearbyAddress(
          {required String addressFragment, required Locale locale}) async =>
      [];
}
