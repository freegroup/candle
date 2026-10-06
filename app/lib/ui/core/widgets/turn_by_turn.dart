import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/ui/core/icons/direction_arrow.dart';
import 'package:candle/ui/core/icons/direction_base.dart';
import 'package:candle/l10n/helper.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

/// The next step of a navigation: meters to the next waypoint, an arrow and a
/// sentence for the turn there. Shows the values of [guidance], the same ones
/// the announcements use.
class TurnByTurnInstructionWidget extends StatelessWidget {
  final NavigationGuidance guidance;

  const TurnByTurnInstructionWidget({super.key, required this.guidance});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;

    String instruction = "";
    if (guidance.hasWaypoint) {
      instruction = sayNavigationInstruction(context, guidance.distanceToWaypoint, guidance.turnAngle);
    }

    return Semantics(
      label: "${sayRotateToWaypoint(context, guidance.waypointRotation, guidance.isAligned)} $instruction",
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const DirectionBaseIcon(
                      height: 80,
                      width: 80,
                    ),
                    DirectionArrowIcon(
                      rotationDegrees: -guidance.turnAngle,
                      height: 80,
                      width: 80,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.remaining_waypoint_distance(guidance.distanceToWaypoint),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                )
              ],
            ),
            const SizedBox(height: 30),
            Text(
              instruction,
              style: theme.textTheme.headlineSmall,
            )
          ],
        ),
      ),
    );
  }
}
