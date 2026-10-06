import 'dart:async';

import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/ui/navigation/announcers/navigation_announcer.dart';
import 'package:flutter/widgets.dart';

/// Full sentences: how far to turn to the next waypoint, how far it is and
/// where the route goes on there, e.g. "You point to the next waypoint.
/// After 50 meters, turn left."
class DetailedStyle extends NavigationStyle {
  const DetailedStyle();

  @override
  String get id => 'detailed';

  @override
  String name(AppLocalizations l10n) => l10n.navigation_style_detailed;

  @override
  String hint(AppLocalizations l10n) => l10n.navigation_style_detailed_hint;

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
            (context) => AppLocalizations.of(context)!.navigation_off_route_t, interrupt: true));
      case NavigationEvent.routeFailed:
        unawaited(output.say(
            (context) => AppLocalizations.of(context)!.navigation_route_failed, interrupt: true));
      case NavigationEvent.targetReached:
        unawaited(output.say(
            (context) => AppLocalizations.of(context)!.location_reached, interrupt: true));
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

  // The same text the screen shows for the screen reader.
  String _directions(BuildContext context, NavigationGuidance guidance) =>
      '${sayRotateToWaypoint(context, guidance.waypointRotation, guidance.isAligned)} '
      '${sayNavigationInstruction(context, guidance.distanceToWaypoint, guidance.turnAngle)}';
}
