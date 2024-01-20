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
    _recordingServiceSubscription = RecorderService.recordingStateStream.listen(
      (RecordingState state) {
        _recordingState = state;
        if (mounted) setState(() => {});
      },
    );
  }

  @override
  void dispose() {
    _recordingServiceSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
