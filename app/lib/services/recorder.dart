import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
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

  static RecordingState _state = RecordingState.stopped;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    _state = (await service.isRunning()) ? RecordingState.recording : RecordingState.stopped;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool backgroundServicePaused = prefs.getBool('backgroundServicePaused') ?? false;
    // If the background job is running and the "paused" flag is set...we
    // set the correct state of the RecordingService
    //
    if (_state == RecordingState.recording && backgroundServicePaused == true) {
      _state = RecordingState.paused;
    }
    _recordingController.add(_state); // Update the stream with the initial state
  }

  static void start() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      print("service already running....ignroed");
    } else {
      print("startService");
      service.startService();
    }
    _state = RecordingState.recording;
    _recordingController.add(_state);
  }

  static void pause() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      service.invoke("pauseService");
      print("pauseService");
    } else {
      print("Service paused...ignored.");
    }

    _state = RecordingState.paused;
    _recordingController.add(_state);
  }

  static void resume() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      print("Service already resumed...ignored.");
    } else {
      service.invoke("resumeService");
      print("resumeService");
    }

    _state = RecordingState.recording;
    _recordingController.add(_state);
  }

  static void stop() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      service.invoke("stopService");
      print("stopService");
    } else {
      print("Service already stopped...ignored.");
    }

    _state = RecordingState.stopped;
    _recordingController.add(_state);
  }

  static RecordingState get state => _state;

  static Stream<RecordingState> get recordingStateStream => _recordingController.stream;

  static void dispose() {
    _recordingController.close();
  }
}
