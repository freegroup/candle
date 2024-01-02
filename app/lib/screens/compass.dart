import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
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
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CandleAppBar(
        title: Text(AppLocalizations.of(context)!.compass_dialog),
        talkback: AppLocalizations.of(context)!.compass_dialog_t,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3, // 2/3 of the screen for the compass
            child: Center(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  double containerWidth = constraints.maxWidth * 0.9;
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
            ),
          ),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Semantics(
              label: '${_currentHeadingDegrees.toStringAsFixed(0)}°',
              child: Align(
                alignment: Alignment.center,
                child: ExcludeSemantics(
                  child: Text(
                    '${_currentHeadingDegrees.toStringAsFixed(0)}°',
                    style: Theme.of(context).textTheme.headlineLarge,
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
    );
  }
}
