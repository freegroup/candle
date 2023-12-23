import 'dart:async';

import 'package:candle/icons/location_arrow.dart';
import 'package:candle/icons/location_dot.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:candle/models/location.dart' as model;
import 'package:vibration/vibration.dart';

class NavigatePoiScreen extends StatefulWidget {
  final model.Location location;

  const NavigatePoiScreen({super.key, required this.location});

  @override
  State<NavigatePoiScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatePoiScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  int _currentHeadingDegrees = 0;
  int _currentDistanceToStateLocation = 0;
  late model.Location stateLocation;
  model.Location? currentLocation;
  Timer? _vibrationTimer;
  bool _wasAligned = false;

  void updateGpsLocation() async {
    var gps = await LocationService.instance.location;
    if (gps != null) {
      currentLocation = model.Location(lat: gps.latitude!, lon: gps.longitude!, name: "");
    }
  }

  bool _isAligned(int headingDegrees) {
    return (headingDegrees.abs() <= 8) || (headingDegrees.abs() >= 352);
  }

  @override
  void initState() {
    super.initState();
    updateGpsLocation();
    Timer.periodic(const Duration(seconds: 10), (Timer t) => updateGpsLocation());

    stateLocation = widget.location;

    _vibrationTimer = Timer.periodic(Duration(seconds: 4), (Timer t) async {
      bool isAligned = (_currentHeadingDegrees.abs() <= 8) || (_currentHeadingDegrees.abs() >= 352);
      if (isAligned && (await Vibration.hasVibrator() ?? false)) {
        Vibration.vibrate(duration: 100); // Vibrate for 500 milliseconds
      }
    });

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        print(err);
      }).listen((compassEvent) async {
        if (mounted && currentLocation != null) {
          var poiHeading = calculateNorthBearing(
            poiBase: currentLocation!,
            poiTarget: stateLocation,
          );
          var deviceHeading = (((compassEvent.heading ?? 0)) % 360).toInt();
          var needleHeading = -(deviceHeading - poiHeading);
          bool currentlyAligned = _isAligned(needleHeading);

          if (currentlyAligned != _wasAligned) {
            if (currentlyAligned) {
              // Aligned: shorter, frequent vibration
              Vibration.vibrate(duration: 100, repeat: 2);
            } else {
              // Misaligned: longer, one-time vibration
              Vibration.vibrate(duration: 500);
            }
            _wasAligned = currentlyAligned;
          }

          setState(() {
            _currentHeadingDegrees = needleHeading;
            _currentDistanceToStateLocation = calculateDistance(
              poiBase: currentLocation!,
              poiTarget: stateLocation,
            ).toInt();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _vibrationTimer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    bool isAligned = _isAligned(_currentHeadingDegrees);
    Color? backgroundColor = isAligned ? Colors.green[800] : null;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(AppLocalizations.of(context)!.compass_dialog),
        talkback: AppLocalizations.of(context)!.compass_dialog_t,
      ),
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Expanded(
              flex: 3, // 2/3 of the screen for the compass
              child: Center(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    double containerWidth = constraints.maxWidth * 0.9;
                    return Semantics(
                      label: sayHorizon(context, _currentHeadingDegrees),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          LocationArrowIcon(
                            shadow: true,
                            rotationDegrees: isAligned ? 0 : _currentHeadingDegrees,
                            height: containerWidth,
                            width: containerWidth,
                          ),
                          LocationDotIcon(
                            shadow: false,
                            height: containerWidth,
                            width: containerWidth,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              child: Semantics(
                label: '${_currentHeadingDegrees.toStringAsFixed(0)}°',
                child: Align(
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          stateLocation.name,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        Text(
                          '${_currentDistanceToStateLocation.toStringAsFixed(0)} Meter',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2, // 1/3 of the screen for the text and buttons
              child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                double buttonWidth = constraints.maxWidth / 4; // 1/3 of the parent width
                return Container(
                  width: double.infinity, // Full width for TalkBack focus
                  child: Semantics(
                    button: true, // Explicitly mark as a button
                    label: AppLocalizations.of(context)!.button_close_t,
                    child: Align(
                      alignment: Alignment.center,
                      child: BoldIconButton(
                        talkback: "",
                        buttonWidth: buttonWidth,
                        icons: Icons.close_rounded,
                        onTab: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
