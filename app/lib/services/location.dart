import 'dart:async';
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
    return _currentLocation ?? await _fetchCurrentLocation();
  }

  // Stream of location updates
  Stream<LocationData> get updates => _location.onLocationChanged;

  void _initLocationUpdates() async {
    _locationSubscription = _location.onLocationChanged.listen((LocationData loc) {
      if (loc.latitude != null && loc.longitude != null) {
        _currentLocation = LatLng(loc.latitude!, loc.longitude!);
      }
    }, onError: (error) {
      print("Location Stream Error: $error");
    });

    _checkPermission().then((hasPermission) {
      if (!hasPermission) {
        print("Location permission not granted");
        // Handle lack of permission as needed
      }
    });
  }

  Future<LatLng?> _fetchCurrentLocation() async {
    try {
      if (await _checkPermission()) {
        LocationData loc = await _location.getLocation();
        if (loc.latitude != null && loc.longitude != null) {
          _currentLocation = LatLng(loc.latitude!, loc.longitude!);
          return _currentLocation;
        }
      }
    } catch (e) {
      print("LocationService Error: $e");
    }
    return null;
  }

  Future<bool> _checkPermission() async {
    if (await _checkService()) {
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          _location.enableBackgroundMode(enable: true);
        }
      }
      return permissionStatus == PermissionStatus.granted;
    }
    return false;
  }

  Future<bool> _checkService() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
      }
      return serviceEnabled;
    } catch (error) {
      print("Service Check Error: $error");
      return false;
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
  }
}
