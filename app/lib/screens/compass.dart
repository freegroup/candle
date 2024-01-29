import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/l10n/helper.dart';

import 'package:candle/services/compass.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/utils/vibrate.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/twoliner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  int _currentHeadingDegrees = 0;
  bool _isCompassHorizontal = true;
  Timer? _horizontalCheckTimer;

  // managmenet vars to check if the phone is tilled and can not show correct
  // the compass information
  //
  static const int _kConsecutiveDuration = 3; // seconds
  int _consecutiveHorizontalFalseCount = 0;
  int _consecutiveHorizontalTrueCount = 0;
  bool _canShowSnackbar = true;

  // vibration and announcement handling
  //
  int? _lastVibratedSnapPoint;

  @override
  void initState() {
    super.initState();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) {
        int heading = ((360 - (compassEvent.heading ?? 0)) % 360).toInt();
        _vibrateAtSnapPoints(heading);

        if (mounted) {
          setState(() {
            _currentHeadingDegrees = heading;
          });
        }
      });

      _horizontalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        bool newIsHorizontal = CompassService.instance.isHorizontal;
        if (mounted) {
          if (_isCompassHorizontal != newIsHorizontal) {
            setState(() {
              _isCompassHorizontal = newIsHorizontal;
            });
          }
          _checkCompassOrientation(newIsHorizontal);
        }
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _horizontalCheckTimer?.cancel();

    super.dispose();
  }

  void _vibrateAtSnapPoints(int heading) {
    const snapPoints = [0, 90, 180, 270];
    const snapRange = 10; // ±10° range for snap points

    for (var point in snapPoints) {
      if ((heading >= point - snapRange) && (heading <= point + snapRange)) {
        if (_lastVibratedSnapPoint != point) {
          CandleVibrate.vibrateCompass(duration: 100);
          SemanticsService.announce(getHorizon(context, heading), TextDirection.ltr);
          _lastVibratedSnapPoint = point;
          break; // Vibrate once and exit loop
        }
      } else if (_lastVibratedSnapPoint == point) {
        // Clear the last vibrated point if we move out of the snap range
        _lastVibratedSnapPoint = null;
      }
    }
  }

  void _checkCompassOrientation(bool isHorizontal) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    if (isHorizontal) {
      _consecutiveHorizontalTrueCount++;
      _consecutiveHorizontalFalseCount = 0;

      if (_consecutiveHorizontalTrueCount >= _kConsecutiveDuration) {
        // Erlaubt die Snackbar-Anzeige, nachdem fünf aufeinanderfolgende "true" erreicht wurden
        _canShowSnackbar = true;
        _consecutiveHorizontalTrueCount = 0;
      }
    } else {
      _consecutiveHorizontalFalseCount++;
      _consecutiveHorizontalTrueCount = 0;

      if (_consecutiveHorizontalFalseCount >= _kConsecutiveDuration && _canShowSnackbar) {
        showSnackbar(context, l10n.compass_hint_horizontal);
        _consecutiveHorizontalFalseCount = 0;
        // Verhindert weitere Snackbar-Anzeigen, bis wieder fünf "true" erreicht wurden
        _canShowSnackbar = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_compass),
        talkback: l10n.screen_header_compass_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double containerWidth = constraints.maxWidth * 0.7;
          return Semantics(
            label: sayHorizon(context, _currentHeadingDegrees),
            child: CompassIcon(
              shadow: true,
              rotationDegrees: _currentHeadingDegrees,
              height: containerWidth,
              width: containerWidth,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    Color color = _isCompassHorizontal ? theme.primaryColor : theme.negativeColor;
    return Column(children: [
      TwolinerWidget(
        color: color,
        headline: '${_currentHeadingDegrees.toStringAsFixed(0)}°',
        headlineTalkback: '${_currentHeadingDegrees.toStringAsFixed(0)}°',
        subtitle: getHorizon(context, _currentHeadingDegrees),
        subtitleTalkback: getHorizon(context, _currentHeadingDegrees),
      ),
      DialogButton(
        label: l10n.button_common_close,
        onTab: () {
          Navigator.pop(context);
        },
        talkback: l10n.button_common_close_t,
      ),
    ]);
  }
}
