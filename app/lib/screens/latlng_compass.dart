import 'dart:async';

import 'package:candle/icons/location_arrow.dart';
import 'package:candle/icons/location_dot.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/models/route.dart' as model;
import 'package:candle/screens/latlng_route.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/screen_wake.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/vibrate.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/twoliner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

class LatLngCompassScreen extends StatefulWidget {
  final LatLng target;
  final String targetName;
  final model.Route? route;

  const LatLngCompassScreen(
      {super.key, required this.target, required this.targetName, this.route});

  @override
  State<LatLngCompassScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LatLngCompassScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _vibrationTimer;
  Timer? _updateLocationTimer;
  int _currentHeadingDegrees = 0;
  int _currentDistanceToStateLocation = 0;

  late LatLng _currentLocation;

  bool _wasAligned = false;

  // vibration and announcement handling
  //
  int? _lastVibratedSnapPoint;

  @override
  void initState() {
    super.initState();

    _updateLocation();
    _updateLocationTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      _updateLocation();
    });

    ScreenWakeService.keepOn(true);
    _vibrationTimer = Timer.periodic(const Duration(seconds: 3), (Timer t) async {
      if (_isAligned(_currentHeadingDegrees)) {
        CandleVibrate.vibrateCompass(duration: 100);
      }
    });

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) async {
        if (mounted) {
          var poiHeading = calculateNorthBearing(_currentLocation, widget.target);
          var deviceHeading = (((compassEvent.heading ?? 0)) % 360).toInt();
          var needleHeading = -(deviceHeading - poiHeading);
          bool currentlyAligned = _isAligned(needleHeading);
          _vibrateAtSnapPoints((needleHeading + 360) % 360);

          if (currentlyAligned != _wasAligned) {
            if (currentlyAligned) {
              CandleVibrate.vibrateCompass(duration: 100, repeat: 2);
            } else {
              CandleVibrate.vibrateCompass(duration: 500);
            }
            _wasAligned = currentlyAligned;
          }

          setState(() {
            _currentHeadingDegrees = needleHeading;
            _currentDistanceToStateLocation = calculateDistance(
              _currentLocation,
              widget.target,
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

  void _vibrateAtSnapPoints(
    int targetHeading,
  ) {
    var distance = calculateDistance(_currentLocation, widget.target);
    const snapPoints = [0, 90, 180, 270];
    const snapRange = 15; // ±15° range for snap points

    for (var point in snapPoints) {
      if ((targetHeading >= point - snapRange) && (targetHeading <= point + snapRange)) {
        if (_lastVibratedSnapPoint != point) {
          var announcement = sayRotateToTarget(
              context, (360 - targetHeading) - 180, _isAligned(targetHeading), distance.toInt());

          CandleVibrate.vibrateCompass(duration: 100);
          SemanticsService.announce(announcement, TextDirection.ltr);
          _lastVibratedSnapPoint = point;
          break; // Vibrate once and exit loop
        }
      } else if (_lastVibratedSnapPoint == point) {
        // Clear the last vibrated point if we move out of the snap range
        _lastVibratedSnapPoint = null;
      }
    }
  }

  bool _isAligned(int headingDegrees) {
    return (headingDegrees.abs() <= 8) || (headingDegrees.abs() >= 352);
  }

  void _updateLocation() async {
    _currentLocation = (await LocationService.instance.location)!;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_compass_poi),
        talkback: l10n.screen_header_compass_poi_t(widget.targetName),
      ),
      body: DividedWidget(
        fraction: screenDividerFraction,
        top: _buildTopPane(context),
        bottom: _buildBottomPane(context),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    bool isAligned = _isAligned(_currentHeadingDegrees);

    return Semantics(
      label: sayRotateToTarget(
          context, _currentHeadingDegrees, isAligned, _currentDistanceToStateLocation),
      child: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double containerWidth = constraints.maxWidth * 0.7;
            return Stack(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    Color? backgroundColor = _wasAligned ? theme.positiveColor : null;

    return Stack(
      children: [
        Container(
          color: backgroundColor,
          height: double.infinity,
          width: double.infinity,
        ),
        Column(
          children: [
            TwolinerWidget(
              headline: widget.targetName,
              headlineTalkback: l10n.location_distance_t(
                widget.targetName,
                _currentDistanceToStateLocation,
              ),
              subtitle: '${_currentDistanceToStateLocation.toStringAsFixed(0)} Meter',
              subtitleTalkback: '${_currentDistanceToStateLocation.toStringAsFixed(0)} Meter',
            ),
            DialogButton(
              label: l10n.button_navigate_poi,
              talkback: l10n.button_navigate_poi_t,
              onTab: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => LatLngRouteScreen(
                    source: _currentLocation,
                    target: widget.target,
                    route: widget.route,
                  ),
                ));
              },
            )
          ],
        ),
      ],
    );
  }
}
