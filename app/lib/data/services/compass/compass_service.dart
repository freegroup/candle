import 'dart:math';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Device heading and orientation. The sensors only run while someone listens.
class CompassService {
  /// The phone counts as flat when it is tilted by less than this.
  static const maxTiltInDegrees = 30.0;

  /// Direction the top of the phone points to, in degrees clockwise from north (0..360).
  Stream<double> headings() => (FlutterCompass.events ?? const Stream<CompassEvent>.empty())
      .where((event) => event.heading != null)
      .map((event) => event.heading! % 360);

  /// Whether the phone is held flat enough for a reliable heading.
  Stream<bool> isHorizontal() => accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
      .map((e) => atan(sqrt(e.x * e.x + e.y * e.y) / e.z).abs() * 180 / pi < maxTiltInDegrees)
      .distinct();
}
