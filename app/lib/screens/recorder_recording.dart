import 'dart:async';

import 'package:candle/models/route.dart' as model;
import 'package:candle/services/compass.dart';
import 'package:candle/services/recorder.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/pulse_icon.dart';
import 'package:candle/widgets/route_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecorderRecordingScreen extends StatefulWidget {
  const RecorderRecordingScreen({super.key});

  @override
  State<RecorderRecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecorderRecordingScreen> {
  late StreamSubscription<CompassEvent> _compassSubscription;
  int _currentMapRotation = 0;

  @override
  void initState() {
    super.initState();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) async {
        var deviceHeading = (((compassEvent.heading ?? 0) + 360) % 360).toInt();

        if (mounted && deviceHeading != _currentMapRotation) {
          setState(() {
            _currentMapRotation = deviceHeading;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _compassSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_recorder_recording),
        talkback: l10n.screen_header_recorder_recording_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPanel(),
          bottom: _buildBottomPane(),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return StreamBuilder<model.Route>(
      stream: RecorderService.routeStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.points.isNotEmpty) {
          model.Route route = snapshot.data!;

          return Stack(
            children: [
              RouteMapWidget(
                route: route,
                mapRotation: -_currentMapRotation.toDouble(),
                currentLocation: route.points.last.latlng(),
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: PulsingRecordIcon(),
              ),
            ],
          );
        } else {
          return Semantics(
            label: l10n.label_common_loading_t,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildBottomPane() {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true, // Explicitly mark as a button
            label: l10n.button_close_t,
            child: BoldIconButton(
              talkback: "",
              buttonWidth: 50,
              icons: Icons.close_outlined,
              onTab: () {
                RecorderService.stop(false);
              },
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true, // Explicitly mark as a button
            label: l10n.button_close_t,
            child: BoldIconButton(
              talkback: "",
              buttonWidth: 120,
              icons: Icons.label_important_outline,
              circle: false,
              onTab: () {
                RecorderService.stop(true);
                Navigator.of(context).pop();
              },
            ),
          ),
        )
      ],
    );
  }
}
