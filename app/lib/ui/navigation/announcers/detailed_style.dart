import 'dart:async';

import 'package:candle/data/services/tts/tts.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/ui/navigation/announcers/abstract_style.dart';
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
  Future<void> announce(NavigationGuidance guidance, BuildContext context) async {
    switch (guidance.event) {
      case NavigationEvent.started:
        // With a given route the directions are known at once, otherwise they come with the route.
        if (guidance.hasWaypoint) await TTS.say(_directions(context, guidance));
      case NavigationEvent.routeCalculated:
        // Not interrupting: it follows the screen title or the off-route announcement.
        unawaited(pulse(context, duration: 100));
        await TTS.say(_directions(context, guidance));
      case NavigationEvent.waypointPassed:
        // the text first: the screen can be gone after waiting for the interruption
        final text = _directions(context, guidance);
        unawaited(pulse(context, duration: 100));
        await TTS.interrupt();
        await TTS.say(text);
      case NavigationEvent.offRoute:
        final text = AppLocalizations.of(context)!.navigation_off_route_t;
        await TTS.interrupt();
        await TTS.say(text);
      case NavigationEvent.routeFailed:
        final text = AppLocalizations.of(context)!.navigation_route_failed;
        await TTS.interrupt();
        await TTS.say(text);
      case NavigationEvent.targetReached:
        final text = AppLocalizations.of(context)!.location_reached;
        await TTS.interrupt();
        await TTS.say(text);
      case NavigationEvent.aligned:
        unawaited(pulse(context, duration: 100, repeat: 2));
      case NavigationEvent.notAligned:
        unawaited(pulse(context, duration: 500));
      case NavigationEvent.update:
        break;
      case NavigationEvent.stopped:
        await TTS.interrupt();
    }
  }

  // The same text the screen shows for the screen reader.
  String _directions(BuildContext context, NavigationGuidance guidance) =>
      '${sayRotateToWaypoint(context, guidance.waypointRotation, guidance.isAligned)} '
      '${sayNavigationInstruction(context, guidance.distanceToWaypoint, guidance.turnAngle)}';
}
