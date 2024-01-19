import 'dart:async';

import 'package:candle/models/route.dart' as model;
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/services/database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RecordingState {
  recording,
  paused,
  stopped,
}

class RecorderService {
  static final BehaviorSubject<RecordingState> _recordingController =
      BehaviorSubject<RecordingState>.seeded(RecordingState.stopped);

  static final BehaviorSubject<List<LatLng>> _locationListController =
      BehaviorSubject<List<LatLng>>.seeded([]);

  static RecordingState _state = RecordingState.stopped;
  static late StreamSubscription<Map<String, dynamic>?> _backgroundStreamSubscription;

  static String _currentRecordingRouteName = "unknown";

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    _state = isRunning ? RecordingState.recording : RecordingState.stopped;

    _backgroundStreamSubscription = service.on('location').listen((event) async {
      print('GOT LOCATION $event');
      if (event != null && event['location'] != null) {
        Map locationMap = event["location"];
        LatLng coord = LatLng(locationMap['latitude'], locationMap['longitude']);
        print('GOT LOCATION  $coord');
        List<LatLng> currentList = _locationListController.value;
        //if (currentList.isEmpty || calculateDistance(coord, currentList.last) > 4) {
        currentList.add(coord);
        _locationListController.add(currentList); // Emit the updated list
        //}
      }
    });

    // If the background job is running and the "paused" flag is set...we
    // set the correct state of the RecordingService
    //
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool backgroundServicePaused = prefs.getBool('backgroundServicePaused') ?? false;
    if (_state == RecordingState.recording && backgroundServicePaused == true) {
      _state = RecordingState.paused;
    }
    _recordingController.add(_state);
  }

  void dispose() {
    _backgroundStreamSubscription.cancel();
    _recordingController.close();
    _locationListController.close();
  }

  static void start(String routeName) async {
    try {
      final service = FlutterBackgroundService();
      if (_state == RecordingState.stopped) {
        _locationListController.add([]);

        await service.startService();
        service.invoke("startedService");
        _currentRecordingRouteName = routeName;
      }
    } finally {
      _setState(RecordingState.recording);
    }
  }

  static Future<void> pause() async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.recording) {
      service.invoke("pauseService");
    }

    _setState(RecordingState.paused);
  }

  static Future<void> resume() async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.paused) {
      service.invoke("resumeService");
      print("resumeService");
    } else {
      print("Service not in 'paused' state.... resume  ignored.");
    }

    _setState(RecordingState.recording);
  }

  static Future<void> stop(bool saveRoute) async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.recording || _state == RecordingState.paused) {
      service.invoke("stopService");
      print("stopService");

      if (saveRoute) {
        List<LatLng> locations = _locationListController.value;
        List<model.NavigationPoint> routePoints = locations.map((latLng) {
          return model.NavigationPoint(coordinate: latLng, annotation: "");
        }).toList();
        model.Route route = model.Route(
          name: _currentRecordingRouteName,
          points: routePoints,
          annotation: "",
        );
        DatabaseService.instance.addRoute(route);
      }
    } else {
      print("Service not 'recording' or 'paused' state.....stop ignored.");
    }

    _setState(RecordingState.stopped);
  }

  static RecordingState get state => _state;

  static bool get isRecordingMode =>
      (_state == RecordingState.recording || _state == RecordingState.paused);

  static Stream<RecordingState> get recordingStateStream => _recordingController.stream;

  static Stream<List<LatLng>> get locationListStream =>
      _locationListController.stream; // Expose the location list stream

  static void _setState(RecordingState state) {
    print("_setState( $state )");
    _state = state;
    _recordingController.add(_state);
  }
}
