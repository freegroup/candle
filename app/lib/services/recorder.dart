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
    final isRunning = await service.isRunning();
    _state = isRunning ? RecordingState.recording : RecordingState.stopped;

    // If the background job is running and the "paused" flag is set...we
    // set the correct state of the RecordingService
    //
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool backgroundServicePaused = prefs.getBool('backgroundServicePaused') ?? false;
    if (_state == RecordingState.recording && backgroundServicePaused == true) {
      _state = RecordingState.paused;
    }
    print("RECORDING_STATE: $_state");
    _recordingController.add(_state); // Update the stream with the initial state
  }

  static void start() async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.recording) {
      print("service already in 'recording' state....'start' ignored");
    } else {
      print("startService");
      service.startService();
    }
    _state = RecordingState.recording;
    _recordingController.add(_state);
  }

  static void pause() async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.recording) {
      service.invoke("pauseService");
      print("pauseService");
    } else {
      print("Service not in 'recording' state...unable to pause");
    }

    _state = RecordingState.paused;
    _recordingController.add(_state);
  }

  static void resume() async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.paused) {
      service.invoke("resumeService");
      print("resumeService");
    } else {
      print("Service not in 'paused' state.... resume  ignored.");
    }

    _state = RecordingState.recording;
    _recordingController.add(_state);
  }

  static void stop() async {
    final service = FlutterBackgroundService();
    if (_state == RecordingState.recording) {
      service.invoke("stopService");
      print("stopService");
    } else {
      print("Service not 'recording' state.....stop ignored.");
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
