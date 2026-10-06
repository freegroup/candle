import 'dart:async';

import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/navigation/announcers/navigation_announcer.dart';
import 'package:flutter/widgets.dart';

/// Only meters and direction, e.g. "50 meters, left"; whether the phone points
/// to the next waypoint is told by vibration only.
class ShortStyle extends NavigationStyle {
  const ShortStyle();

  @override
  String get id => 'short';

  @override
  String name(AppLocalizations l10n) => l10n.navigation_style_short;

  @override
  String hint(AppLocalizations l10n) => l10n.navigation_style_short_hint;

  @override
  void announce(NavigationGuidance guidance, NavigationOutput output) {
    switch (guidance.event) {
      case NavigationEvent.started:
        // With a given route the directions are known at once, otherwise they come with the route.
        if (guidance.hasWaypoint) unawaited(output.say((context) => _directions(context, guidance)));
      case NavigationEvent.routeCalculated:
        // Not interrupting: it follows the screen title or the off-route announcement.
        unawaited(output.vibrate());
        unawaited(output.say((context) => _directions(context, guidance)));
      case NavigationEvent.waypointPassed:
        unawaited(output.vibrate());
        unawaited(output.say((context) => _directions(context, guidance), interrupt: true));
      case NavigationEvent.offRoute:
        unawaited(output.say(
            (context) => AppLocalizations.of(context)!.navigation_short_off_route_t, interrupt: true));
      case NavigationEvent.routeFailed:
        unawaited(output.say(
            (context) => AppLocalizations.of(context)!.navigation_short_route_failed_t, interrupt: true));
      case NavigationEvent.targetReached:
        unawaited(output.say(
            (context) => AppLocalizations.of(context)!.navigation_short_target_reached_t, interrupt: true));
      case NavigationEvent.aligned:
        unawaited(output.vibrate(repeat: 2));
      case NavigationEvent.notAligned:
        unawaited(output.vibrate(duration: 500));
      case NavigationEvent.update:
        break;
      case NavigationEvent.stopped:
        unawaited(output.stopSpeaking());
    }
  }

  String _directions(BuildContext context, NavigationGuidance guidance) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.navigation_short_directions_t(guidance.distanceToWaypoint, _turn(l10n, guidance.turnAngle));
  }

  // Positive angles turn left, negative ones right.
  String _turn(AppLocalizations l10n, int angle) {
    if (angle >= 135) return l10n.navigation_short_hard_left_t;
    if (angle > 45) return l10n.navigation_short_left_t;
    if (angle > 15) return l10n.navigation_short_slightly_left_t;
    if (angle <= -135) return l10n.navigation_short_hard_right_t;
    if (angle < -45) return l10n.navigation_short_right_t;
    if (angle < -15) return l10n.navigation_short_slightly_right_t;
    return l10n.navigation_short_straight_t;
  }
}
