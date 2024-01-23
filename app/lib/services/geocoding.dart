import 'package:candle/models/location_address.dart' as model;
import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/geocoding_osm.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

abstract class GeocodingService {
  Future<model.LocationAddress?> getGeolocationAddress(LatLng coord);
  Future<List<model.LocationAddress>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  });
}

class GeoServiceProvider extends ChangeNotifier {
  GeoServiceProvider();

  //final GeocodingService _geo = GoogleMapsGeocodingService();
  final GeocodingService _geo = OSMGeocodingService();

  GeocodingService get service => _geo;
}
