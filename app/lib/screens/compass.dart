import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/services/compass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeadingDegrees = 0;

  @override
  void initState() {
    super.initState();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        print(err);
      }).listen((compassEvent) {
        if (mounted) {
          setState(() {
            _currentHeadingDegrees = (360 - (compassEvent.heading ?? 0)) % 360;
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
      appBar: AppBar(
        title: Text('Compass Screen'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2, // 2/3 of the screen for the compass
            child: Center(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  double containerWidth = constraints.maxWidth * 0.9;
                  return CompassSvgIcon(
                    rotationDegrees: _currentHeadingDegrees,
                    height: containerWidth,
                    width: containerWidth,
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 1, // 1/3 of the screen for the text and buttons
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentHeadingDegrees.toStringAsFixed(0)}°',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the screen
                      },
                      child: Text('Close'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Implement the 'Speak' functionality
                      },
                      child: Text('Speak'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
