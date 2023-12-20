import 'dart:async';

import 'package:flutter/services.dart';
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

  Future<LocationData?> get location async {
    if (await _checkPermission()) {
      return _location.getLocation();
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
