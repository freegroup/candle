import 'dart:async';

import 'package:candle/data/services/compass/compass_service.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// What every screen that works with the direction of the phone needs: the
/// heading, and a warning when the phone is not held flat (the heading is
/// unreliable then).
abstract class BaseCompassViewModel extends ChangeNotifier {
  BaseCompassViewModel({
    required CompassService compassService,
    this.tiltWarningDelay = const Duration(seconds: 3),
  }) {
    listen(compassService.headings(), _onHeading);
    listen(compassService.isHorizontal(), _onHorizontal);
  }

  final Duration tiltWarningDelay;
  final _subscriptions = <StreamSubscription<Object?>>[];

  int? _heading;

  /// Clockwise degrees from north the phone points to, 0..359 (0 until the first reading).
  int get heading => _heading ?? 0;

  bool _isTilted = false;

  /// True once the phone has been tilted for [tiltWarningDelay], false again
  /// after it has been held flat for as long.
  bool get isTilted => _isTilted;

  Timer? _tiltTimer;
  bool? _horizontal;

  /// Called when the heading changed by at least a degree, before the listeners
  /// are notified.
  @protected
  void onHeadingChanged(int heading) {}

  /// Listens to [stream] until the view model is disposed.
  @protected
  void listen<T>(Stream<T> stream, void Function(T value) onData) => _subscriptions
      .add(stream.listen(onData, onError: (Object e) => _log.w('Sensor stream error: $e')));

  void _onHeading(double heading) {
    final rounded = heading.round() % 360;
    if (rounded == _heading) return;
    _heading = rounded;
    onHeadingChanged(rounded);
    notifyListeners();
  }

  void _onHorizontal(bool horizontal) {
    if (horizontal == _horizontal) return;
    _horizontal = horizontal;
    _tiltTimer?.cancel();
    if (_isTilted == !horizontal) return;
    _tiltTimer = Timer(tiltWarningDelay, () {
      _isTilted = !horizontal;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _tiltTimer?.cancel();
    super.dispose();
  }
}
