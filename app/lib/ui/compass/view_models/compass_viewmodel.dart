import 'dart:async';

import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// A direction counts as reached within ±[snapRange]° around it.
const snapRange = 10;

/// The compass direction (0, 45, … 315) within ±[snapRange]° of [heading], or null.
int? snapToDirection(int heading) {
  final nearest = (heading / 45).round() % 8 * 45;
  final diff = (heading - nearest).abs() % 360;
  return (diff > 180 ? 360 - diff : diff) <= snapRange ? nearest : null;
}

/// The heading of the phone, snapped to the eight compass directions, and a
/// warning when the phone is not held flat (the compass is wrong then).
class CompassViewModel extends ChangeNotifier {
  CompassViewModel({
    required CompassService compassService,
    this.tiltWarningDelay = const Duration(seconds: 3),
  }) {
    _subscriptions = [
      compassService.headings().listen(_onHeading, onError: _logError),
      compassService.isHorizontal().listen(_onHorizontal, onError: _logError),
    ];
  }

  final Duration tiltWarningDelay;
  late final List<StreamSubscription<Object>> _subscriptions;

  int _heading = 0;

  /// Clockwise degrees from north, 0..359.
  int get heading => _heading;

  int? _snappedDirection;

  /// The compass direction the phone points to, null between two directions.
  int? get snappedDirection => _snappedDirection;

  bool _isTilted = false;

  /// True once the phone has been tilted for [tiltWarningDelay], false again
  /// after it has been held flat for as long.
  bool get isTilted => _isTilted;

  Timer? _tiltTimer;
  bool? _horizontal;

  void _onHeading(double heading) {
    final rounded = heading.round() % 360;
    if (rounded == _heading) return;
    _heading = rounded;
    _snappedDirection = snapToDirection(rounded);
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

  void _logError(Object e) => _log.w('Compass error: $e');

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _tiltTimer?.cancel();
    super.dispose();
  }
}

/// Direction and distance from the user to a [target], relative to the heading of the phone.
class TargetCompassViewModel extends ChangeNotifier {
  TargetCompassViewModel({
    required CompassService compassService,
    required LocationService locationService,
    required this.target,
    required this.targetName,
  }) {
    _subscriptions = [
      compassService.headings().listen(_onHeading, onError: _logError),
      locationService.positions().listen(_onPosition, onError: _logError),
    ];
    unawaited(locationService.currentPosition().then((result) {
      if (result case Ok(:final value) when _position == null) _onPosition(value);
    }));
  }

  final LatLng target;
  final String targetName;
  late final List<StreamSubscription<Object>> _subscriptions;

  LatLng? _position;

  /// The user's position, null until the first GPS fix.
  LatLng? get position => _position;

  int _deviceHeading = 0;

  /// Clockwise degrees from where the phone points to the target, 0..359.
  int get targetHeading => _position == null
      ? 0
      : (_deviceHeading - calculateNorthBearing(_position!, target).round()) % 360;

  /// Whether the phone points to the target.
  bool get isAligned => _position != null && snapToDirection(targetHeading) == 0;

  /// The compass direction of the target relative to the phone, null between two directions.
  int? get snappedDirection => _position == null ? null : snapToDirection(targetHeading);

  /// Meters to the target, 0 without a GPS position.
  int get distance => _position == null ? 0 : calculateDistance(_position!, target).round();

  void _onHeading(double heading) {
    final rounded = heading.round() % 360;
    if (rounded == _deviceHeading) return;
    _deviceHeading = rounded;
    notifyListeners();
  }

  void _onPosition(LatLng position) {
    _position = position;
    notifyListeners();
  }

  void _logError(Object e) => _log.w('Compass or GPS error: $e');

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
