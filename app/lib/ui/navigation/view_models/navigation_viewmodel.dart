import 'dart:async';

import 'package:candle/config/app_config.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Guides the user along a route to [target]: the phone points to the next
/// waypoint, and the route is calculated anew when the user leaves it.
class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({
    required RoutingRepository routingRepository,
    required LocationNoteRepository locationNoteRepository,
    required LocationService locationService,
    required CompassService compassService,
    required LatLng source,
    required this.target,
    this._route,
  })  : _routing = routingRepository,
        _position = source {
    _subscriptions = [
      locationService.positions().listen(_onPosition, onError: _logError),
      compassService.headings().listen(_onHeading, onError: _logError),
    ];
    unawaited(locationNoteRepository.watchAll().first.then((pins) {
      _locationNotes = pins;
      notifyListeners();
    }, onError: _logError));
    _updateWaypoints();
  }

  final LatLng target;
  final RoutingRepository _routing;
  late final List<StreamSubscription<Object>> _subscriptions;

  Route? _route;

  /// The route followed, null while it is calculated.
  Route? get route => _route;

  bool _routeFailed = false;

  /// True when no route could be calculated; a new attempt follows the next position.
  bool get routeFailed => _routeFailed;

  bool _calculating = false;

  LatLng _position;
  LatLng get position => _position;

  int _deviceHeading = 0;

  /// Clockwise degrees from north the phone points to.
  int get deviceHeading => _deviceHeading;

  int _segmentIndex = -1;

  NavigationPoint? _headingWaypoint;

  /// The waypoint the user walks to right now.
  NavigationPoint? get headingWaypoint => _headingWaypoint;

  NavigationPoint? _turnWaypoint;

  /// The waypoint after [headingWaypoint], for the turn instruction.
  NavigationPoint? get turnWaypoint => _turnWaypoint;

  NavigationPoint? _nextTurnWaypoint;
  NavigationPoint? get nextTurnWaypoint => _nextTurnWaypoint;

  bool _targetReached = false;
  bool get targetReached => _targetReached;

  List<LocationNote> _locationNotes = [];

  /// Voice pins to show on the map.
  List<LocationNote> get locationNotes => _locationNotes;

  final _reachedLocationNotes = StreamController<LocationNote>.broadcast();

  /// A location note the user just reached. It comes again only after the user was
  /// [LocationNoteConfig.resetDistance] away from it, or in a new navigation.
  Stream<LocationNote> get reachedLocationNotes => _reachedLocationNotes.stream;

  final _announcedLocationNotes = <LocationNote>{};

  /// Bearing from the user to [headingWaypoint].
  int get waypointHeading =>
      _headingWaypoint == null ? 0 : calculateNorthBearing(_position, _headingWaypoint!.latlng());

  /// Whether the phone points to [headingWaypoint] (±[NavigationConfig.alignedTolerance]°).
  bool get isAligned {
    if (_headingWaypoint == null) return false;
    final diff = (_deviceHeading - waypointHeading).abs();
    return diff <= NavigationConfig.alignedTolerance || diff >= 360 - NavigationConfig.alignedTolerance;
  }

  /// Rotation of the arrow that points to [headingWaypoint].
  int get needleHeading => -(_deviceHeading - waypointHeading);

  /// Meters to [turnWaypoint].
  int get distanceToTurn =>
      _turnWaypoint == null ? 0 : calculateDistance(_position, _turnWaypoint!.latlng()).round();

  /// Meters along the route to the target.
  int get distanceToTarget {
    final route = _route;
    final waypoint = _headingWaypoint;
    if (route == null || waypoint == null) return 0;
    return route.calculateResumingLengthFromWaypoint(waypoint).round() + distanceToTurn;
  }

  void _onPosition(LatLng position) {
    _position = position;
    _updateWaypoints();
    _updateLocationNotes();
    notifyListeners();
  }

  void _onHeading(double heading) {
    final rounded = heading.round() % 360;
    if (rounded == _deviceHeading) return;
    _deviceHeading = rounded;
    notifyListeners();
  }

  void _updateLocationNotes() {
    _announcedLocationNotes.removeWhere(
        (note) => calculateDistance(note.latlng(), _position) >= LocationNoteConfig.resetDistance);
    final nearest = _locationNotes
        .where((note) =>
            !_announcedLocationNotes.contains(note) &&
            calculateDistance(note.latlng(), _position) < LocationNoteConfig.announceDistance)
        .fold<LocationNote?>(
            null,
            (best, note) => best == null ||
                    calculateDistance(note.latlng(), _position) <
                        calculateDistance(best.latlng(), _position)
                ? note
                : best);
    if (nearest == null) return;
    _announcedLocationNotes.add(nearest);
    _reachedLocationNotes.add(nearest);
  }

  Future<void> _calculateRoute() async {
    if (_calculating) return;
    _calculating = true;
    final result = await _routing.walkingRoute(_position, target);
    _calculating = false;
    switch (result) {
      case Ok(:final value):
        _route = value;
        _routeFailed = false;
        // The waypoints of the new route are counted from its start.
        _segmentIndex = -1;
        // Not again before the next position, even if the route starts away from the user.
        _updateWaypoints(recalculate: false);
      case Error(:final error):
        _log.w('Calculating the route failed: $error');
        _routeFailed = true;
    }
    notifyListeners();
  }

  void _updateWaypoints({bool recalculate = true}) {
    if (_targetReached) return;
    final route = _route;
    if (route == null || route.points.length < 2) {
      if (recalculate) unawaited(_calculateRoute());
      return;
    }

    final closest = route.findClosestSegment(_position);
    if ((closest['distance'] as double) > NavigationConfig.offRouteDistance) {
      _log.d('Left the route by ${closest['distance']} m, calculating a new one');
      if (recalculate) unawaited(_calculateRoute());
      return;
    }

    final points = route.points;
    var start = (closest['start'] as Map<String, dynamic>)['index'] as int;
    var next = (closest['end'] as Map<String, dynamic>)['index'] as int;
    while (next < points.length &&
        calculateDistance(_position, points[next].latlng()) < NavigationConfig.waypointPassedDistance) {
      start = next;
      next++;
    }
    if (start <= _segmentIndex) return;

    _segmentIndex = start;
    if (start >= points.length - 1) {
      _targetReached = true;
      return;
    }
    _headingWaypoint = points[start + 1];
    _turnWaypoint = _headingWaypoint;
    _nextTurnWaypoint = _headingWaypoint;
    if (start + 2 < points.length) {
      _turnWaypoint = points[start + 2];
      _nextTurnWaypoint = _turnWaypoint;
    }
    if (start + 3 < points.length) {
      _nextTurnWaypoint = points[start + 3];
    } else if (_headingWaypoint == _nextTurnWaypoint &&
        calculateDistance(_position, _headingWaypoint!.latlng()) <
            NavigationConfig.waypointPassedDistance * 2) {
      // the last waypoint is almost reached
      _targetReached = true;
    }
  }

  void _logError(Object e) => _log.w('Navigation sensor error: $e');

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_reachedLocationNotes.close());
    super.dispose();
  }
}
