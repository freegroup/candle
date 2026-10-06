import 'dart:async';

import 'package:candle/config/app_config.dart';
import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// One navigation along a route to [target]: follows the position and the
/// heading, calculates the route (anew when the user leaves it), tracks the
/// waypoints and reports what happens in [guidance]. It knows no screen: the
/// view model, the announcer or anyone else listen to [guidance].
class NavigationController {
  NavigationController({
    required RoutingRepository routingRepository,
    required LocationNoteAnnouncer locationNoteAnnouncer,
    required LocationService locationService,
    required CompassService compassService,
    required LatLng source,
    required this.target,
    this._route,
  })  : _routing = routingRepository,
        _locationNotes = locationNoteAnnouncer,
        _location = locationService,
        _compass = compassService,
        _position = source;

  final LatLng target;
  final RoutingRepository _routing;
  final LocationNoteAnnouncer _locationNotes;
  final LocationService _location;
  final CompassService _compass;

  bool _started = false;

  // A route can arrive after the navigation stopped.
  bool _stopped = false;

  var _subscriptions = <StreamSubscription<Object>>[];

  final _guidance = StreamController<NavigationGuidance>.broadcast();

  /// One guidance per event, [NavigationEvent.update] when only the position or
  /// the heading changed; the first one is [NavigationEvent.started] at [start],
  /// the last one [NavigationEvent.stopped] at [stop].
  Stream<NavigationGuidance> get guidance => _guidance.stream;

  // The events found while handling one position, heading or route; sent by _report.
  final _events = <NavigationEvent>[];

  bool _wasAligned = false;

  // So that leaving the route is reported once, not with every position away from it.
  bool _offRoute = false;

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

  /// Bearing from the user to [headingWaypoint].
  int get waypointHeading =>
      _headingWaypoint == null ? 0 : calculateNorthBearing(_position, _headingWaypoint!.latlng());

  /// Whether the phone points to [headingWaypoint] (±[NavigationConfig.alignedTolerance]°).
  bool get isAligned {
    if (_headingWaypoint == null) return false;
    final diff = (_deviceHeading - waypointHeading).abs();
    return diff <= NavigationConfig.alignedTolerance || diff >= 360 - NavigationConfig.alignedTolerance;
  }

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

  /// Begins the navigation. Listen to [guidance] before, so that nothing is missed.
  void start() {
    if (_started) return;
    _started = true;
    // the location note announcer reports the notes on the way
    _locationNotes.startNavigation();
    _subscriptions = [
      _location.positions().listen(_onPosition, onError: _logError),
      _compass.headings().listen(_onHeading, onError: _logError),
    ];
    _events.add(NavigationEvent.started);
    _updateWaypoints();
    _report();
  }

  /// Ends the navigation with [NavigationEvent.stopped].
  void stop() {
    if (_stopped) return;
    _stopped = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    if (_started) _locationNotes.stopNavigation();
    _guidance.add(const NavigationGuidance(event: NavigationEvent.stopped));
    unawaited(_guidance.close());
  }

  void _onPosition(LatLng position) {
    _position = position;
    _updateWaypoints();
    _report();
  }

  void _onHeading(double heading) {
    final rounded = heading.round() % 360;
    if (rounded == _deviceHeading) return;
    _deviceHeading = rounded;
    _report();
  }

  /// Sends the collected events as guidance, [NavigationEvent.update] when there is none.
  void _report() {
    final aligned = isAligned;
    if (aligned != _wasAligned) {
      _wasAligned = aligned;
      _events.add(aligned ? NavigationEvent.aligned : NavigationEvent.notAligned);
    }
    if (_events.isEmpty) _events.add(NavigationEvent.update);
    for (final event in _events) {
      _guidance.add(_guidanceFor(event));
    }
    _events.clear();
  }

  NavigationGuidance _guidanceFor(NavigationEvent event) {
    final waypoint = _headingWaypoint;
    if (waypoint == null) return NavigationGuidance(event: event);
    final turn = _turnWaypoint;
    var turnAngle = 0;
    if (turn != null && turn != waypoint) {
      turnAngle = _signedAngle(calculateNorthBearing(_position, waypoint.latlng()) -
          calculateNorthBearing(waypoint.latlng(), turn.latlng()));
    }
    return NavigationGuidance(
      event: event,
      hasWaypoint: true,
      distanceToWaypoint: calculateDistance(_position, waypoint.latlng()).round(),
      turnAngle: turnAngle,
      waypointRotation: _signedAngle(waypointHeading - _deviceHeading),
      isAligned: isAligned,
      distanceToTarget: distanceToTarget,
    );
  }

  /// [degrees] as -180..180, e.g. 340 as -20.
  static int _signedAngle(int degrees) => (degrees + 540) % 360 - 180;

  Future<void> _calculateRoute() async {
    if (_calculating) return;
    _calculating = true;
    final result = await _routing.walkingRoute(_position, target);
    _calculating = false;
    if (_stopped) return;
    switch (result) {
      case Ok(:final value):
        _route = value;
        _routeFailed = false;
        // The waypoints of the new route are counted from its start.
        _segmentIndex = -1;
        _events.add(NavigationEvent.routeCalculated);
        // Not again before the next position, even if the route starts away from the user.
        _updateWaypoints(recalculate: false);
      case Error(:final error):
        _log.w('Calculating the route failed: $error');
        if (!_routeFailed) _events.add(NavigationEvent.routeFailed);
        _routeFailed = true;
    }
    _report();
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
      if (!_offRoute) _events.add(NavigationEvent.offRoute);
      _offRoute = true;
      if (recalculate) unawaited(_calculateRoute());
      return;
    }
    _offRoute = false;

    final points = route.points;
    var start = (closest['start'] as Map<String, dynamic>)['index'] as int;
    var next = (closest['end'] as Map<String, dynamic>)['index'] as int;
    while (next < points.length &&
        calculateDistance(_position, points[next].latlng()) < NavigationConfig.waypointPassedDistance) {
      start = next;
      next++;
    }
    if (start <= _segmentIndex) return;

    // The first waypoint of a route is no passed one.
    if (_segmentIndex >= 0) _events.add(NavigationEvent.waypointPassed);
    _segmentIndex = start;
    if (start >= points.length - 1) {
      _reachTarget();
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
      _reachTarget();
    }
  }

  void _reachTarget() {
    _targetReached = true;
    _events.add(NavigationEvent.targetReached);
  }

  void _logError(Object e) => _log.w('Navigation sensor error: $e');
}
