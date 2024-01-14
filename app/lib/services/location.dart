import 'dart:async';
import 'package:candle/utils/global_logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationService {
  static final LocationService instance = LocationService._privateConstructor();
  final Location _location = Location();

  LatLng? _currentLocation;

  StreamSubscription<LocationData>? _locationSubscription;

  LocationService._privateConstructor() {
    _initLocationUpdates();
  }

  Future<LatLng?> get location async {
    return _currentLocation ?? await _lazyInitCurrentLocation();
  }

  // Stream of location updates
  Stream<LocationData> get updates => _location.onLocationChanged;

  Future<void> _configureLocationSettings() async {
    _location.changeSettings(
      accuracy: LocationAccuracy.high, // Set high accuracy
      interval: 1000, // Update every second
      distanceFilter: 1, // Update every meter
    );
  }

  void _initLocationUpdates() async {
    await _configureLocationSettings();

    // Enable background mode
    await _location.enableBackgroundMode(enable: true);

    _locationSubscription = _location.onLocationChanged.listen((LocationData loc) {
      if (loc.latitude != null && loc.longitude != null) {
        _currentLocation = LatLng(loc.latitude!, loc.longitude!);
      }
    }, onError: (error) {
      log.e("Location Stream Error: $error");
    });
  }

  Future<LatLng?> _lazyInitCurrentLocation() async {
    try {
      LocationData loc = await _location.getLocation();
      if (loc.latitude != null && loc.longitude != null) {
        _currentLocation = LatLng(loc.latitude!, loc.longitude!);
        return _currentLocation;
      }
    } catch (e) {
      log.e("LocationService Error: $e");
    }
    return null;
  }

  void dispose() {
    _locationSubscription?.cancel();
  }
}
