import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/geocoding_osm.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:candle/models/location.dart' as model;

abstract class GeocodingService {
  Future<LocationAddress?> getGeolocationAddress({required double lat, required double lon});
}

class GeoServiceProvider extends ChangeNotifier {
  GeoServiceProvider() {
    _listenToLocationChanges();
  }
  LocationData? _lastLocation;

  GeocodingService _geo = GoogleMapsGeocodingService();
  //GeocodingService _geo = OSMGeocodingService();
  LocationAddress _address = LocationAddress(
    street: "",
    number: "",
    zip: "",
    city: "",
    country: "",
  );

  GeocodingService get geo => _geo;
  LocationAddress get address => _address;

  void set(GeocodingService service) {
    _geo = service;
    notifyListeners();
  }

  void _listenToLocationChanges() {
    LocationService.instance.updates.handleError((dynamic err) {
      print(err);
    }).listen((currentLocation) async {
      if (_shouldUpdateLocationAddress(currentLocation)) {
        await _updateLocationAddress(currentLocation);
      }
    });
  }

  bool _shouldUpdateLocationAddress(LocationData currentLocation) {
    if (_lastLocation == null) return true;

    final distance = calculateDistance(
        poiBase:
            model.Location(lat: _lastLocation!.latitude!, lon: _lastLocation!.longitude!, name: ""),
        poiTarget: model.Location(
            lat: currentLocation.latitude!, lon: currentLocation.longitude!, name: ""));

    return distance > 10; // Check if the distance is more than 10 meters
  }

  Future<void> _updateLocationAddress(LocationData currentLocation) async {
    print("UPDATE ADDRESS........$_geo");
    final newAddress = await _geo.getGeolocationAddress(
      lat: currentLocation.latitude!,
      lon: currentLocation.longitude!,
    );

    if (newAddress != null) {
      _address = newAddress;
      _lastLocation = currentLocation;
      notifyListeners();
    }
  }
}
