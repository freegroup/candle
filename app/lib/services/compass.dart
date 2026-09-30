import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CompassService {
  // Singleton Pattern
  CompassService._privateConstructor();
  static final CompassService instance = CompassService._privateConstructor();

  Stream<CompassEvent>? _compassStream;
  StreamController<CompassEvent>? _streamController;
  bool _hasPermissions = false;
  bool _isHorizontal = false;

  // Initialize the compass stream with permission check
  Future<void> initialize() async {
    // Called by every screen that shows a heading. Register the sensor listeners
    // only once, otherwise each call adds more listeners until the UI thread
    // is flooded with sensor events (ANR on Android).
    if (_streamController != null) return;
    _hasPermissions = await _checkPermissions();
    if (_hasPermissions) {
      _compassStream = FlutterCompass.events;
      _streamController = StreamController<CompassEvent>.broadcast();
      _compassStream?.listen((event) {
        _streamController?.add(event);
      });
      accelerometerEventStream().listen(_onAccelerometerChanged);
    }
  }

  // Handler for accelerometer updates
  void _onAccelerometerChanged(AccelerometerEvent event) {
    double angle = atan(sqrt(event.x * event.x + event.y * event.y) / event.z) * (180 / pi);
    _isHorizontal = (angle < 30.0 && angle > -30.0);
  }

  // Stream of compass updates
  Stream<CompassEvent> get updates {
    if (_compassStream == null || _streamController == null) {
      initialize();
    }
    return _streamController!.stream;
  }

  // Check and request necessary permissions
  Future<bool> _checkPermissions() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    return status.isGranted;
  }

  // Get horizontal state
  bool get isHorizontal => _isHorizontal;

  // Dispose resources
  void dispose() {
    _streamController?.close();
    _streamController = null;
  }
}
