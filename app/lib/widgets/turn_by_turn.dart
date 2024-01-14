import 'package:candle/icons/direction_arrow.dart';
import 'package:candle/icons/direction_base.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/models/navigation_point.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TurnByTurnInstructionWidget extends StatelessWidget {
  final LatLng? currentCoord;
  final NavigationPoint? waypoint1;
  final NavigationPoint? waypoint2;
  final bool isAligned;
  final int bearing;

  const TurnByTurnInstructionWidget(
      {this.currentCoord,
      this.waypoint1,
      this.waypoint2,
      super.key,
      required this.isAligned,
      required this.bearing});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;

    String instruction = "";
    int mapRotation = 0;
    int distance = 0;
    if (currentCoord != null && waypoint1 != null) {
      distance = calculateDistance(currentCoord!, waypoint1!.latlng()).toInt();
      int angle1 = calculateNorthBearing(currentCoord!, waypoint1!.latlng());
      if (waypoint2 != null && waypoint1 != waypoint2) {
        int angle2 = calculateNorthBearing(waypoint1!.latlng(), waypoint2!.latlng());
        instruction = sayNavigationInstruction(context, distance, angle1 - angle2);
        mapRotation = angle1 - angle2;
      } else {
        instruction = sayNavigationInstruction(context, distance, 0);
      }
    }

    return Semantics(
      label: "${sayRotateToWaypoint(context, bearing, isAligned)} $instruction",
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
                      rotationDegrees: -mapRotation,
                      height: 80,
                      width: 80,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.remaining_waypoint_distance(distance),
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
