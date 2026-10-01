import 'dart:async';

import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// The distance from the user to a [target], updated while the user walks.
class DistanceViewModel extends ChangeNotifier {
  DistanceViewModel({required LocationService locationService, required this.target}) {
    _positions = locationService.positions().listen(_onPosition,
        onError: (Object e) => _log.w('Position stream error: $e'));
    unawaited(locationService.currentPosition().then((result) {
      if (result case Ok(:final value) when _distance == null) _onPosition(value);
    }));
  }

  final LatLng target;
  late final StreamSubscription<LatLng> _positions;

  int? _distance;

  /// Meters to [target], null until the first GPS position.
  int? get distance => _distance;

  void _onPosition(LatLng position) {
    _distance = calculateDistance(position, target).round();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_positions.cancel());
    super.dispose();
  }
}
