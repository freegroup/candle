import 'dart:async';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationService {
  // singleton Pattern
  LocationService._privateConstructor() {
    _location = Location();
  }
  static final LocationService instance = LocationService._privateConstructor();

  late Location _location;
  bool _serviceEnabled = false;
  PermissionStatus? _grantedPermissions;

  Future<LatLng?> get location async {
    if (await _checkPermission()) {
      LocationData loc = await _location.getLocation();
      if (loc.latitude != null && loc.longitude != null) {
        return LatLng(loc.latitude!, loc.longitude!);
      }
    }
    return null;
  }

  Stream<LocationData> get updates {
    return _location.onLocationChanged;
  }

  Future<bool> _checkPermission() async {
    if (await _checkService()) {
      _grantedPermissions = await _location.hasPermission();
      if (_grantedPermissions == PermissionStatus.denied) {
        _grantedPermissions = await _location.requestPermission();
        _location.enableBackgroundMode(enable: true);
      }
    }
    return _grantedPermissions == PermissionStatus.granted;
  }

  Future<bool> _checkService() async {
    try {
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
      }
    } on PlatformException catch (error) {
      print(error);
      _serviceEnabled = false;
      await _checkService();
    }
    return _serviceEnabled;
  }
}
