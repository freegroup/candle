import 'dart:async';

import 'package:candle/screens/talkback.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RecorderScreen extends TalkbackScreen {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _ScreenState();

  @override
  String getTalkback(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return l10n.compass_dialog_t;
  }
}

class _ScreenState extends State<RecorderScreen> {
  late StreamSubscription<RecordingState> _recordingServiceSubscription;
  RecordingState _recordingState = RecordingState.stopped;

  late StreamSubscription<Position> _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges();

    // Subscribe to the RecorderService state
    _recordingServiceSubscription = RecorderService.recordingStateStream.listen(
      (RecordingState state) {
        setState(() {
          _recordingState = state;
        });
      },
    );

    // Initial check of the recording state
    _recordingState = RecorderService.state;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _recordingServiceSubscription.cancel();
    _locationSubscription.cancel();
  }

  void _listenToLocationChanges() {
    print("LOCATION SUBSCRIPTION");
    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      log.e(err);
    }).listen((newLocation) async {
      LatLng coord = LatLng(newLocation.latitude, newLocation.longitude);
      print(coord);
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.compass_dialog),
        talkback: widget.getTalkback(context),
      ),
      body: BackgroundWidget(
        child: _recordingState != RecordingState.stopped
            ? _buildTopPanel()
            : DividedWidget(
                fraction: screenDividerFraction,
                top: _buildTopPanel(),
                bottom: _buildBottomPane(),
              ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_recordingState == RecordingState.stopped)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                RecorderService.start();
              },
              child: Text('Start'),
            ),
          SizedBox(height: 28),
          if (_recordingState == RecordingState.paused)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                RecorderService.resume();
              },
              child: Text('Resume'),
            ),
          SizedBox(height: 28),
          if (_recordingState == RecordingState.paused ||
              _recordingState == RecordingState.recording)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                RecorderService.stop();
              },
              child: Text('Stop'),
            ),
          SizedBox(height: 28),
          if (_recordingState == RecordingState.recording)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                RecorderService.pause();
              },
              child: Text('Pause'),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPane() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Column(children: [
      if (_recordingState == RecordingState.stopped)
        Container(
          width: double.infinity, // Full width for TalkBack focus
          child: Semantics(
            button: true, // Explicitly mark as a button
            label: l10n.button_close_t,
            child: BoldIconButton(
              talkback: "",
              buttonWidth: MediaQuery.of(context).size.width / 5,
              icons: Icons.close_rounded,
              onTab: () {
                Navigator.pop(context);
              },
            ),
          ),
        )
    ]);
  }
}
