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

  static final BehaviorSubject<model.Route> _routeController =
      BehaviorSubject<model.Route>.seeded(model.Route(name: "", points: []));

  static RecordingState _state = RecordingState.stopped;
  static late StreamSubscription<Map<String, dynamic>?> _backgroundStreamSubscription;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    _state = isRunning ? RecordingState.recording : RecordingState.stopped;

    _backgroundStreamSubscription = service.on('route_updated').listen((event) async {
      print('GOT $event');
      if (event != null && event['routeName'] != null) {
        var eventRouteName = event['routeName'] as String;
        var route = await DatabaseService.instance.getRouteByName(eventRouteName);
        if (route != null) {
          _routeController.add(route); // Emit the updated list
        }
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
    _routeController.close();
  }

  static void start(String routeName) async {
    try {
      final service = FlutterBackgroundService();
      if (_state == RecordingState.stopped) {
        _routeController.add(model.Route(name: "", points: []));

        // Start the service first
        await service.startService();

        // Then, invoke the method once the service is running
        // otherwise the message is not delivered...
        service.invoke("startedService", {"routeName": routeName});
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

      if (!saveRoute) {
        // remove the already store Route from the DB
        model.Route route = _routeController.value;
        DatabaseService.instance.removeRoute(route);
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
  static Stream<model.Route> get routeStream => _routeController.stream;

  static void _setState(RecordingState state) {
    _state = state;
    _recordingController.add(_state);
  }
}
