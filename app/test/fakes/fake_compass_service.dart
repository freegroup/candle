import 'dart:async';

import 'package:candle/data/services/compass/compass_service.dart';

class FakeCompassService implements CompassService {
  // Live as long as the test; closing is not needed for broadcast fakes.
  // ignore: close_sinks
  final headingController = StreamController<double>.broadcast();
  // ignore: close_sinks
  final horizontalController = StreamController<bool>.broadcast();

  @override
  Stream<double> headings() => headingController.stream;

  @override
  Stream<bool> isHorizontal() => horizontalController.stream;
}
