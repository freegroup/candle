import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationService {
  LocationService._privateConstructor();

  static final LocationService instance = LocationService._privateConstructor();

  final Location _location = Location();

  Future<LatLng?> get location async {
    try {
      print("location.get");
      if (await _checkPermission()) {
        LocationData loc = await _location.getLocation();
        if (loc.latitude != null && loc.longitude != null) {
          return LatLng(loc.latitude!, loc.longitude!);
        }
      }
    } catch (e) {
      print("LocationService Error: $e");
    }
    return null;
  }

  Stream<LocationData> get updates {
    return _location.onLocationChanged.handleError((error) {
      print("Location Stream Error: $error");
    });
  }

  Future<bool> _checkPermission() async {
    if (await _checkService()) {
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        _location.enableBackgroundMode(enable: true);
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
}
