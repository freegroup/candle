import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String getHorizon(BuildContext context, int angle) {
  var l10n = AppLocalizations.of(context)!;
  List<String> directions = [
    l10n.compassHorizonNorth, // "Norden"
    l10n.compassHorizonNorthNortheast, // "Nord-Nordost"
    l10n.compassHorizonNortheast, // "Nordost"
    l10n.compassHorizonEastNortheast, // "Ost-Nordost"
    l10n.compassHorizonEast, // "Osten"
    l10n.compassHorizonEastSoutheast, // "Ost-Südost"
    l10n.compassHorizonSoutheast, // "Südost"
    l10n.compassHorizonSouthSoutheast, // "Süd-Südost"
    l10n.compassHorizonSouth, // "Süden"
    l10n.compassHorizonSouthSouthwest, // "Süd-Südwest"
    l10n.compassHorizonSouthwest, // "Südwest"
    l10n.compassHorizonWestSouthwest, // "West-Südwest"
    l10n.compassHorizonWest, // "Westen"
    l10n.compassHorizonWestNorthwest, // "West-Nordwest"
    l10n.compassHorizonNorthwest, // "Nordwest"
    l10n.compassHorizonNorthNorthwest, // "Nord-Nordwest"
  ];

  int segment = (angle / 22.5).round() % 16;
  return directions[segment];
}

String sayHorizon(BuildContext context, int angle) {
  return AppLocalizations.of(context)!
      .compassDirection(getHorizon(context, angle)); // "Sie halten das Handy in Richtung {}"
}

String sayRotate(BuildContext context, int angle, bool isAligned, int distance) {
  AppLocalizations l10n = AppLocalizations.of(context)!;

  if (isAligned == true) {
    return l10n.label_rotate_no_t(distance);
  }
  if (angle > 180 || angle < 0) {
    return l10n.label_rotate_left_t(angle.abs());
  }

  return l10n.label_rotate_right_t(angle.abs());
}

String sayNavigationInstruction(BuildContext context, int meters, int angle) {
  var l10n = AppLocalizations.of(context)!;
  String turn;

  if (angle >= 135 || angle <= -135) {
    turn = l10n.turnHardLeft;
  } else if (angle > 45) {
    turn = l10n.turnLeft;
  } else if (angle > 15) {
    turn = l10n.turnSlightlyLeft;
  } else if (angle < -45) {
    turn = l10n.turnRight;
  } else if (angle < -15) {
    turn = l10n.turnSlightlyRight;
  } else {
    turn = l10n.straightAhead;
  }

  return l10n.turnInstruction(meters, turn);
}
