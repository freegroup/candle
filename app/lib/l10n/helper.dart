import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String getHorizon(BuildContext context, int angle) {
  List<String> directions = [
    AppLocalizations.of(context)!.compassHorizonNorth, // "Norden"
    AppLocalizations.of(context)!.compassHorizonNorthNortheast, // "Nord-Nordost"
    AppLocalizations.of(context)!.compassHorizonNortheast, // "Nordost"
    AppLocalizations.of(context)!.compassHorizonEastNortheast, // "Ost-Nordost"
    AppLocalizations.of(context)!.compassHorizonEast, // "Osten"
    AppLocalizations.of(context)!.compassHorizonEastSoutheast, // "Ost-Südost"
    AppLocalizations.of(context)!.compassHorizonSoutheast, // "Südost"
    AppLocalizations.of(context)!.compassHorizonSouthSoutheast, // "Süd-Südost"
    AppLocalizations.of(context)!.compassHorizonSouth, // "Süden"
    AppLocalizations.of(context)!.compassHorizonSouthSouthwest, // "Süd-Südwest"
    AppLocalizations.of(context)!.compassHorizonSouthwest, // "Südwest"
    AppLocalizations.of(context)!.compassHorizonWestSouthwest, // "West-Südwest"
    AppLocalizations.of(context)!.compassHorizonWest, // "Westen"
    AppLocalizations.of(context)!.compassHorizonWestNorthwest, // "West-Nordwest"
    AppLocalizations.of(context)!.compassHorizonNorthwest, // "Nordwest"
    AppLocalizations.of(context)!.compassHorizonNorthNorthwest, // "Nord-Nordwest"
  ];

  int segment = (angle / 22.5).round() % 16;
  return directions[segment]; // "Sie halten das Handy in Richtung {}"
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
