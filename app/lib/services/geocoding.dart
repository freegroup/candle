import 'package:candle/models/route.dart' as model;
import 'package:candle/models/location_address.dart' as model;
import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/geocoding_osm.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

abstract class GeocodingService {
  Future<model.LocationAddress?> getGeolocationAddress(LatLng coord);
  Future<List<model.LocationAddress>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  });
}

class GeoServiceProvider extends ChangeNotifier {
  GeoServiceProvider() {
    _initialize();
  }
  LatLng _lastLocation = const LatLng(0, 0);

  GeocodingService _service = GoogleMapsGeocodingService();
  //GeocodingService _service = OSMGeocodingService();
  model.LocationAddress? _currentAddress;

  GeocodingService get service => _service;
  model.LocationAddress? get currentAddress => _currentAddress;

  void set(GeocodingService service) {
    _service = service;
    notifyListeners();
  }

  void _initialize() async {
    // Get the initial location
    LatLng initialCoord = await _fetchInitialLocation();
    if (initialCoord.latitude != 0 && initialCoord.longitude != 0) {
      // Update the address for the initial location
      await _updateLocationAddress(initialCoord);
    }
    // Start listening to location changes
    _listenToLocationChanges();
  }

  Future<LatLng> _fetchInitialLocation() async {
    try {
      var currentLocation = await LocationService.instance.location;
      return currentLocation ?? const LatLng(0, 0);
    } catch (e) {
      log.e("Error fetching initial location: $e");
      return const LatLng(0, 0); // Return a default location in case of error
    }
  }

  void _listenToLocationChanges() {
    LocationService.instance.updates.handleError((dynamic err) {
      log.e(err);
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
    log.d("UPDATE ADDRESS........$_service");
    final newAddress = await _service.getGeolocationAddress(currentLocation);

    if (newAddress != null) {
      _currentAddress = newAddress;
      _lastLocation = currentLocation;
      notifyListeners();
    }
  }
}
