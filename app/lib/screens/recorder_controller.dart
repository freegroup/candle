import 'dart:async';

import 'package:candle/screens/recorder_pause.dart';
import 'package:candle/screens/recorder_recording.dart';
import 'package:candle/screens/recorder_start.dart';
import 'package:candle/services/recorder.dart';
import 'package:flutter/material.dart';

class RecorderControllerScreen extends StatefulWidget {
  const RecorderControllerScreen({super.key});

  @override
  State<RecorderControllerScreen> createState() => _ScreenState();
}

class _ScreenState extends State<RecorderControllerScreen> {
  late StreamSubscription<RecordingState> _recordingServiceSubscription;
  RecordingState _recordingState = RecorderService.state;

  @override
  void initState() {
    super.initState();
    print("initState: $runtimeType");
    _recordingServiceSubscription = RecorderService.recordingStateStream.listen(
      (RecordingState state) {
        print("STATE CHANGE EVENT..........$state vs. $_recordingState");
        _recordingState = state;
        if (mounted) {
          setState(() {
            print("SET STATE FOR CONTROLLER $state");
          });
        }
      },
    );
  }

  @override
  void dispose() {
    print("dispose: $runtimeType");
    _recordingServiceSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("build: $RecorderControllerScreen  $_recordingState");
    switch (_recordingState) {
      case RecordingState.recording:
        return const RecorderRecordingScreen();
      case RecordingState.paused:
        return const RecorderPauseScreen();
      default:
        return const RecorderStartScreen();
    }
  }
}
