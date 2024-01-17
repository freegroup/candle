import 'dart:async';
import 'package:candle/utils/global_logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService instance = LocationService._privateConstructor();
  LatLng? _currentLocation;
  late StreamSubscription<Position> _locationSubscription;

  LocationService._privateConstructor() {
    _initLocationUpdates();
  }

  Future<LatLng?> get location async {
    return _currentLocation ?? await _lazyInitCurrentLocation();
  }

  // Stream of location updates
  Stream<Position> get listen => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ),
      );

  void _initLocationUpdates() async {
    // Enable background mode

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position loc) {
      _currentLocation = LatLng(loc.latitude, loc.longitude);
    }, onError: (error) {
      log.e("Location Stream Error: $error");
    });
  }

  Future<LatLng?> _lazyInitCurrentLocation() async {
    try {
      Position loc = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _currentLocation = LatLng(loc.latitude, loc.longitude);
      return _currentLocation;
    } catch (e) {
      log.e("LocationService Error: $e");
    }
    return null;
  }

  void dispose() {
    _locationSubscription.cancel();
  }
}
