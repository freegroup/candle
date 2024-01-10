import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/screens/talkback.dart';
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

class CompassScreen extends TalkbackScreen {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();

  @override
  String getTalkback(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return l10n.compass_dialog_t;
  }
}

class _CompassScreenState extends State<CompassScreen> {
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
        title: Text(l10n.compass_dialog),
        talkback: widget.getTalkback(context),
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
    ThemeData theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;
    Color color = _isCompassHorizontal ? theme.primaryColor : theme.negativeColor;
    return Column(
      children: [
        TwolinerWidget(
          color: color,
          headline: '${_currentHeadingDegrees.toStringAsFixed(0)}°',
          headlineTalkback: '${_currentHeadingDegrees.toStringAsFixed(0)}°',
          subtitle: getHorizon(context, _currentHeadingDegrees),
          subtitleTalkback: getHorizon(context, _currentHeadingDegrees),
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
    );
  }
}
