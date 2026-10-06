/// What a [NavigationGuidance] is about.
enum NavigationEvent {
  /// Only the position or the heading changed.
  update,

  /// The navigation began; with a given route the first waypoint is known already.
  started,

  /// The first route or a new one is ready.
  routeCalculated,

  /// The user left the route; a new one is calculated.
  offRoute,

  /// No route could be calculated; a new attempt follows the next position.
  routeFailed,

  /// The user passed a waypoint and walks to the next one.
  waypointPassed,

  /// The phone points to the next waypoint now.
  aligned,

  /// The phone does not point to the next waypoint any more.
  notAligned,

  targetReached,

  /// The user left the navigation; the last guidance.
  stopped,
}

/// One moment of a navigation, for the announcements: the [event] and the
/// directions at that moment.
class NavigationGuidance {
  const NavigationGuidance({
    required this.event,
    this.hasWaypoint = false,
    this.distanceToWaypoint = 0,
    this.turnAngle = 0,
    this.waypointRotation = 0,
    this.isAligned = false,
    this.distanceToTarget = 0,
  });

  final NavigationEvent event;

  /// Whether the next waypoint is known; without it the other values are 0.
  final bool hasWaypoint;

  /// Meters to the next waypoint.
  final int distanceToWaypoint;

  /// How the route turns at the next waypoint, in degrees (-180..180): positive
  /// turns left, negative right, 0 goes straight on.
  final int turnAngle;

  /// How far the user has to turn to point to the next waypoint, in degrees
  /// (-180..180): negative to the left, positive to the right.
  final int waypointRotation;

  /// Whether the phone points to the next waypoint.
  final bool isAligned;

  /// Meters along the route to the target.
  final int distanceToTarget;

  @override
  String toString() => 'NavigationGuidance($event, waypoint: $distanceToWaypoint m, '
      'turn: $turnAngle°, rotation: $waypointRotation°, aligned: $isAligned)';
}
