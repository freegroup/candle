import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/screens/fab.dart';

import 'package:candle/services/compass.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/twoliner.dart';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> implements FloatingActionButtonProvider {
  StreamSubscription<CompassEvent>? _compassSubscription;
  int _currentHeadingDegrees = 0;
  bool _isCompassHorizontal = true;
  Timer? _horizontalCheckTimer;

  static const int _kConsecutiveDuration = 3; // seconds
  int _consecutiveHorizontalFalseCount = 0;
  int _consecutiveHorizontalTrueCount = 0;
  bool _canShowSnackbar = true;

  @override
  void initState() {
    super.initState();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) {
        if (mounted) {
          setState(() {
            _currentHeadingDegrees = ((360 - (compassEvent.heading ?? 0)) % 360).toInt();
          });
        }
      });

      _horizontalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        bool newIsHorizontal = CompassService.instance.isHorizontal;
        if (_isCompassHorizontal != newIsHorizontal && mounted) {
          setState(() {
            _isCompassHorizontal = newIsHorizontal;
          });
        }
        _checkCompassOrientation(newIsHorizontal);
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _horizontalCheckTimer?.cancel();

    super.dispose();
  }

  @override
  Widget? floatingActionButton(BuildContext context) {
    return null;
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
    double screenDividerFraction = screenHeight * (5 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_compass_t),
        talkback: l10n.screen_header_compass_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(),
          bottom: _buildBottomPane(),
        ),
      ),
    );
  }

  Widget _buildTopPane() {
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

  Widget _buildBottomPane() {
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
