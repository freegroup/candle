import 'dart:async';

import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/ui/compass/view_models/base_compass_viewmodel.dart';
import 'package:candle/ui/core/widgets/report_covered.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Places in the direction the phone points to.
///
/// The heading snaps to the eight compass directions (N, NE, E, …); between
/// them the last direction is kept.
class RadarViewModel extends BaseCompassViewModel implements CoveredAware {
  RadarViewModel({
    required this._poiRepository,
    required this._locationService,
    required super.compassService,
    this.radiusInMeter = 2000,
    this.reloadDistanceInMeter = 500,
    super.tiltWarningDelay,
  }) {
    load = Command0(_load)..execute();
  }

  /// All explore categories except crossings: there are far too many of them
  /// (~1500 within 2 km in Berlin Mitte) and they drown the other places.
  static final categories = PoiCategory.values.toSet()..remove(PoiCategory.crossings);

  /// A direction (entered within ±[snapRange]°) shows the places within
  /// ±[directionRange]° around it.
  static const directionRange = 25;

  final int radiusInMeter;
  final int reloadDistanceInMeter;
  final PoiRepository _poiRepository;
  final LocationService _locationService;

  late final Command0<void> load;

  LatLng? _location;
  LatLng? get location => _location;

  List<Poi> _pois = [];

  /// Compass direction (0, 45, … 315) the phone points to right now,
  /// null while it is between two directions.
  int? _snappedDirection;
  int? get snappedDirection => _snappedDirection;

  /// The last direction the phone pointed to, null until the first one.
  int? _direction;
  int? get direction => _direction;

  List<Poi> _poisInDirection = [];

  /// Places in [direction], closest first.
  List<Poi> get poisInDirection => _poisInDirection;


  LatLng? _loadedAt;
  StreamSubscription<LatLng>? _positions;

  int distanceTo(Poi poi) =>
      _location == null ? 0 : calculateDistance(poi.position, _location!).round();

  Future<Result<void>> _load() async {
    final position = _location ?? await _currentPosition();
    if (position == null) return Result.error(Exception('No GPS position available'));
    _location = position;

    final result = await _poiRepository.findNearby(categories, position, radiusInMeter: radiusInMeter);
    switch (result) {
      case Ok(:final value):
        _pois = value;
        _loadedAt = position;
        _followPosition();
        _updatePoisInDirection();
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _log.w('Loading POIs failed: $error');
        return Result.error(error);
    }
  }

  Future<LatLng?> _currentPosition() async {
    final result = await _locationService.currentPosition();
    return result is Ok<LatLng> ? result.value : null;
  }

  void _followPosition() {
    _positions ??= _locationService.positions().listen(_onPosition, onError: _logError);
  }

  /// While another screen covers the radar its list is not updated; it catches up
  /// when the radar is on top again. Compass and position keep coming.
  bool _covered = false;

  @override
  void onCovered() => _covered = true;

  @override
  void onUncovered() {
    _covered = false;
    onHeadingChanged(heading);
    _refresh();
  }

  void _onPosition(LatLng position) {
    _location = position;
    if (!_covered) _refresh();
  }

  void _refresh() {
    final position = _location;
    if (position == null) return;
    _pois = [..._pois]..sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    _updatePoisInDirection();
    notifyListeners();

    final loadedAt = _loadedAt;
    if (loadedAt != null &&
        !load.running &&
        calculateDistance(loadedAt, position) > reloadDistanceInMeter) {
      unawaited(load.execute());
    }
  }

  @override
  void onHeadingChanged(int heading) {
    if (_covered) return;
    final snapped = snapToDirection(heading);
    if (snapped == _snappedDirection) return;
    _snappedDirection = snapped;
    if (snapped != null) {
      _direction = snapped;
      _updatePoisInDirection();
    }
  }

  void _updatePoisInDirection() {
    final direction = _direction;
    final location = _location;
    if (direction == null || location == null) return;
    _poisInDirection = [
      for (final poi in _pois)
        if (angleBetween(calculateNorthBearing(location, poi.position), direction) <=
            directionRange)
          poi,
    ];
  }


  void _logError(Object e) => _log.w('Sensor stream error: $e');

  @override
  void dispose() {
    unawaited(_positions?.cancel());
    load.dispose();
    super.dispose();
  }
}
