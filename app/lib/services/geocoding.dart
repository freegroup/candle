import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:location/location.dart';
import 'package:candle/models/location.dart' as model;
import 'package:flutter/material.dart';

abstract class GeocodingService {
  Future<LocationAddress?> getGeolocationAddress({required double lat, required double lon});
  Future<List<AddressSearchResult>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  });
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

class AddressSearchResult {
  final String formattedAddress;
  final double lat;
  final double lng;

  AddressSearchResult({required this.formattedAddress, required this.lat, required this.lng});

  factory AddressSearchResult.fromJson(Map<String, dynamic> json) {
    return AddressSearchResult(
      formattedAddress:
          json['vicinity'], // Use 'vicinity' or 'formatted_address' based on your preference
      lat: json['geometry']['location']['lat'],
      lng: json['geometry']['location']['lng'],
    );
  }

  @override
  String toString() {
    return 'AddressSearchResult(formattedAddress: $formattedAddress, lat: $lat, lng: $lng)';
  }
}
