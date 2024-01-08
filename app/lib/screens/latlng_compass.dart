import 'dart:async';

import 'package:candle/icons/location_arrow.dart';
import 'package:candle/icons/location_dot.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/screens/latlng_route.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/screen_wake.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

class LatLngCompassScreen extends StatefulWidget {
  final LatLng target;
  final String targetName;

  const LatLngCompassScreen({super.key, required this.target, required this.targetName});

  @override
  State<LatLngCompassScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LatLngCompassScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _vibrationTimer;
  Timer? _updateLocationTimer;
  int _currentHeadingDegrees = 0;
  int _currentDistanceToStateLocation = 0;
  late LatLng _stateLocation;
  late LatLng _currentLocation;

  bool _wasAligned = false;

  bool _isAligned(int headingDegrees) {
    return (headingDegrees.abs() <= 8) || (headingDegrees.abs() >= 352);
  }

  void updateGpsLocation() async {
    _currentLocation = (await LocationService.instance.location)!;
  }

  @override
  void initState() {
    super.initState();
    _stateLocation = widget.target;

    updateGpsLocation();
    _updateLocationTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      updateGpsLocation();
    });

    ScreenWakeService.keepOn(true);
    _vibrationTimer = Timer.periodic(const Duration(seconds: 3), (Timer t) async {
      if (_isAligned(_currentHeadingDegrees) && (await Vibration.hasVibrator() ?? false)) {
        Vibration.vibrate(duration: 100);
      }
    });

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) async {
        if (mounted) {
          var poiHeading = calculateNorthBearing(_currentLocation, _stateLocation);
          var deviceHeading = (((compassEvent.heading ?? 0)) % 360).toInt();
          var needleHeading = -(deviceHeading - poiHeading);
          bool currentlyAligned = _isAligned(needleHeading);

          if (currentlyAligned != _wasAligned) {
            if (currentlyAligned) {
              Vibration.vibrate(duration: 100, repeat: 2);
            } else {
              Vibration.vibrate(duration: 500);
            }
            _wasAligned = currentlyAligned;
          }

          setState(() {
            _currentHeadingDegrees = needleHeading;
            _currentDistanceToStateLocation = calculateDistance(
              _currentLocation,
              _stateLocation,
            ).toInt();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    ScreenWakeService.keepOn(false);
    _compassSubscription?.cancel();
    _vibrationTimer?.cancel();
    _updateLocationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    bool isAligned = _isAligned(_currentHeadingDegrees);
    Color? backgroundColor = isAligned ? theme.positiveColor : null;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.compass_dialog),
        talkback: l10n.compass_poi_dialog_t(widget.targetName),
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
                      label: sayRotate(context, _currentHeadingDegrees, isAligned,
                          _currentDistanceToStateLocation),
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
                label: l10n.location_distance_t(
                  widget.targetName,
                  _currentDistanceToStateLocation,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          widget.targetName,
                          style: theme.textTheme.displayMedium,
                        ),
                        Text(
                          '${_currentDistanceToStateLocation.toStringAsFixed(0)} Meter',
                          style: theme.textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(),
            ),
            BoldIconButton(
                talkback: l10n.button_navigate_poi_t,
                buttonWidth: MediaQuery.of(context).size.width / 5,
                icons: Icons.near_me,
                onTab: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => LatLngRouteScreen(
                      source: _currentLocation,
                      target: _stateLocation,
                    ),
                  ));
                }),
            BoldIconButton(
              talkback: l10n.button_close_t,
              buttonWidth: MediaQuery.of(context).size.width / 7,
              icons: Icons.close,
              onTab: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
