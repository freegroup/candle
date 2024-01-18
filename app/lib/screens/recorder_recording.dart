import 'dart:async';
import 'package:candle/models/route.dart' as model;
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/route_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
    print("initState: $runtimeType");

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
        title: Text(l10n.recorder_dialog),
        talkback: l10n.recorder_dialog_t,
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
    ThemeData theme = Theme.of(context);

    return StreamBuilder<List<LatLng>>(
      stream: RecorderService.locationListStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<LatLng> locations = snapshot.data!;
          List<model.NavigationPoint> routePoints = locations.map((latLng) {
            return model.NavigationPoint(coordinate: latLng, annotation: "");
          }).toList();
          model.Route route = model.Route(name: "Recorder", points: routePoints, annotation: "");
          return RouteMapWidget(
            route: route,
            mapRotation: -_currentMapRotation.toDouble(),
            currentLocation: locations.last,
          );
        } else {
          return const Text("Waiting for locations...");
        }
      },
    );
  }

  Widget _buildBottomPane() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true, // Explicitly mark as a button
            label: l10n.button_close_t,
            child: BoldIconButton(
              talkback: "",
              buttonWidth: 50,
              icons: Icons.pause,
              onTab: () {
                RecorderService.pause();
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
              buttonWidth: 50,
              icons: Icons.close,
              onTab: () {
                RecorderService.stop();
                Navigator.of(context).pop();
              },
            ),
          ),
        )
      ],
    );
  }
}
