import 'package:candle/models/route.dart' as model;
import 'package:candle/models/location_address.dart' as model;
import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

abstract class GeocodingService {
  Future<model.Route?> getPedestrianRoute(LatLng start, LatLng end);
  Future<model.LocationAddress?> getGeolocationAddress(LatLng coord);
  Future<List<model.LocationAddress>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  });
}

class GeoServiceProvider extends ChangeNotifier {
  GeoServiceProvider() {
    _listenToLocationChanges();
  }
  LatLng _lastLocation = const LatLng(0, 0);

  GeocodingService _service = GoogleMapsGeocodingService();
  //GeocodingService _geo = OSMGeocodingService();
  model.LocationAddress? _currentAddress;

  GeocodingService get service => _service;
  model.LocationAddress? get currentAddress => _currentAddress;

  void set(GeocodingService service) {
    _service = service;
    notifyListeners();
  }

  void _listenToLocationChanges() {
    LocationService.instance.updates.handleError((dynamic err) {
      print(err);
    }).listen((currentLocation) async {
      if (currentLocation.latitude == null || currentLocation.longitude == null) {
        return;
      }
      LatLng coord = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      if (_shouldUpdateLocationAddress(coord)) {
        await _updateLocationAddress(coord);
      }
    });
  }

  bool _shouldUpdateLocationAddress(LatLng currentLocation) {
    final distance = calculateDistance(currentLocation, _lastLocation);
    return distance > 10; // Check if the distance is more than 10 meters
  }

  Future<void> _updateLocationAddress(LatLng currentLocation) async {
    print("UPDATE ADDRESS........$_service");
    final newAddress = await _service.getGeolocationAddress(currentLocation);

    if (newAddress != null) {
      _currentAddress = newAddress;
      _lastLocation = currentLocation;
      notifyListeners();
    }
  }
}
