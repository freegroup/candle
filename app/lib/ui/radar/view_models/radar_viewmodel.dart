import 'dart:async';

import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Places in the direction the phone points to.
///
/// The heading snaps to the eight compass directions (N, NE, E, …); between
/// them the last direction is kept.
class RadarViewModel extends ChangeNotifier {
  RadarViewModel({
    required this._poiRepository,
    required this._locationService,
    required this._compassService,
    this.radiusInMeter = 2000,
    this.reloadDistanceInMeter = 500,
    this.tiltWarningDelay = const Duration(seconds: 3),
  }) {
    load = Command0(_load)..execute();
    _subscriptions.add(_compassService.headings().listen(_onHeading, onError: _logError));
    _subscriptions.add(_compassService.isHorizontal().listen(_onHorizontal, onError: _logError));
  }

  /// All explore categories except crossings: there are far too many of them
  /// (~1500 within 2 km in Berlin Mitte) and they drown the other places.
  static final categories = PoiCategory.values.toSet()..remove(PoiCategory.crossings);

  /// A direction is entered within ±[snapRange]° around it …
  static const snapRange = 10;

  /// … and shows the places within ±[directionRange]° around it.
  static const directionRange = 25;

  final int radiusInMeter;
  final int reloadDistanceInMeter;
  final Duration tiltWarningDelay;
  final PoiRepository _poiRepository;
  final LocationService _locationService;
  final CompassService _compassService;

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

  /// True once the phone has been tilted for [tiltWarningDelay], false again
  /// after it has been held flat for as long.
  bool _isTilted = false;
  bool get isTilted => _isTilted;

  LatLng? _loadedAt;
  final List<StreamSubscription<Object>> _subscriptions = [];
  StreamSubscription<LatLng>? _positions;
  Timer? _tiltTimer;

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

  void _onPosition(LatLng position) {
    _location = position;
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

  void _onHeading(double heading) {
    final nearest = (heading / 45).round() % 8 * 45;
    final snapped = _angleBetween(heading, nearest) <= snapRange ? nearest : null;
    if (snapped == _snappedDirection) return;

    _snappedDirection = snapped;
    if (snapped != null) {
      _direction = snapped;
      _updatePoisInDirection();
    }
    notifyListeners();
  }

  void _updatePoisInDirection() {
    final direction = _direction;
    final location = _location;
    if (direction == null || location == null) return;
    _poisInDirection = [
      for (final poi in _pois)
        if (_angleBetween(calculateNorthBearing(location, poi.position), direction) <=
            directionRange)
          poi,
    ];
  }

  void _onHorizontal(bool isHorizontal) {
    _tiltTimer?.cancel();
    if (isHorizontal == !_isTilted) return;
    _tiltTimer = Timer(tiltWarningDelay, () {
      _isTilted = !isHorizontal;
      notifyListeners();
    });
  }

  /// Smallest angle between two compass directions (0..180).
  static num _angleBetween(num a, num b) {
    final difference = (a - b).abs() % 360;
    return difference > 180 ? 360 - difference : difference;
  }

  void _logError(Object e) => _log.w('Sensor stream error: $e');

  @override
  void dispose() {
    _tiltTimer?.cancel();
    unawaited(_positions?.cancel());
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    load.dispose();
    super.dispose();
  }
}
