import 'dart:async';

import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/ui/compass/view_models/base_compass_viewmodel.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Direction and distance from the user to a [target], relative to the heading of the phone.
class TargetCompassViewModel extends BaseCompassViewModel {
  TargetCompassViewModel({
    required super.compassService,
    required LocationService locationService,
    required this.target,
    required this.targetName,
  }) {
    listen(locationService.positions(), _onPosition);
    unawaited(locationService.currentPosition().then((result) {
      if (result case Ok(:final value) when _position == null) _onPosition(value);
    }));
  }

  final LatLng target;
  final String targetName;

  LatLng? _position;

  /// The user's position, null until the first GPS fix.
  LatLng? get position => _position;

  /// Clockwise degrees from where the phone points to the target, 0..359.
  int get targetHeading => _position == null
      ? 0
      : (heading - calculateNorthBearing(_position!, target).round()) % 360;

  /// Whether the phone points to the target.
  bool get isAligned => _position != null && snapToDirection(targetHeading) == 0;

  /// The compass direction of the target relative to the phone, null between two directions.
  int? get snappedDirection => _position == null ? null : snapToDirection(targetHeading);

  /// Meters to the target, 0 without a GPS position.
  int get distance => _position == null ? 0 : calculateDistance(_position!, target).round();

  void _onPosition(LatLng position) {
    _position = position;
    notifyListeners();
  }
}
