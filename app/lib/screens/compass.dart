import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/utils/shadow.dart';
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
        print(err);
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
                  return CompassIcon(
                    shadow: true,
                    rotationDegrees: _currentHeadingDegrees,
                    height: containerWidth,
                    width: containerWidth,
                  );
                },
              ),
            ),
          ),
          Text(
            '${_currentHeadingDegrees.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Expanded(
            flex: 2, // 1/3 of the screen for the text and buttons
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              double buttonWidth = constraints.maxWidth / 3; // 1/3 of the parent width
              return BoldIconButton(
                talkback: AppLocalizations.of(context)!.button_close_t,
                buttonWidth: buttonWidth,
                icons: Icons.close_rounded,
                onTab: () {
                  Navigator.pop(context);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
