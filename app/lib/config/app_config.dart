// Compile-time settings of the app, one class per screen or service.
// Values that differ per build (keys, server overrides) are in environment.dart.

abstract final class StoreConfig {
  static const appStoreLink = 'https://apps.apple.com/de/app/candle-navigation-app/id6478289375';
  static const playStoreLink = 'https://play.google.com/store/apps/details?id=de.freegroup.candle.app';
}

abstract final class HttpConfig {
  // OpenStreetMap services (Overpass, Nominatim) and Wikipedia reject requests
  // with the default "Dart/x.y (dart:io)" User-Agent.
  static const headers = {
    'User-Agent': 'Candle/1.4 (de.freegroup.candle; +https://github.com/freegroup/candle)',
  };
}

abstract final class SnackbarConfig {
  /// How long a message stays on screen (unless it is kept, see showSnackbar).
  static const duration = Duration(seconds: 3);
}

abstract final class VibrationConfig {
  /// Length of one pulse of a pulse series, in milliseconds.
  static const pulseLength = 200;

  /// Pause between two pulses, in milliseconds.
  static const pulsePause = 150;
}

abstract final class NavigationConfig {
  /// A waypoint counts as passed within this many meters.
  static const waypointPassedDistance = 5;

  /// Farther away from the route than this many meters, a new route is calculated.
  static const offRouteDistance = 15;

  /// The phone points to the next waypoint within this many degrees.
  static const alignedTolerance = 8;
}

abstract final class LocationNoteConfig {
  /// While navigating, a note closer than this many meters is announced.
  static const announceDistance = 8;

  /// After moving this many meters away, a note is announced again on return.
  static const resetDistance = 50;

  /// Vibration pulses when a note is announced.
  static const vibrationCount = 3;
}

abstract final class IndoorConfig {
  /// GPS accuracy (radius in meters) that counts as outdoors; better is never indoors.
  static const goodAccuracy = 10.0;

  /// GPS accuracy (meters) that counts as indoors; in between it is scaled.
  static const badAccuracy = 30.0;

  /// Longest wait for a fresh GPS fix; none in time counts as bad accuracy.
  static const fixTimeout = Duration(seconds: 5);

  /// Building outlines within this many meters are checked.
  static const buildingSearchRadius = 30;

  /// Longest wait for the building outlines; without them only the accuracy counts.
  static const mapTimeout = Duration(seconds: 4);

  /// Share of the GPS accuracy and of "inside a building outline" in the probability.
  static const accuracyWeight = 0.6;
  static const buildingWeight = 0.4;

  /// From this probability on the user counts as indoors (or with poor GPS reception).
  static const threshold = 0.6;
}

abstract final class OrsConfig {
  /// openrouteservice servers, asked in this order until one answers.
  /// api.openrouteservice.org is deprecated in favour of api.heigit.org (same key).
  static const servers = ['https://api.heigit.org/openrouteservice'];
}

abstract final class OverpassConfig {
  // Tested 10/2026. Both have worldwide data and are run in the EU. Not used:
  // private.coffee and kumi.systems did not answer, overpass.osm.ch has Swiss data
  // only, maps.mail.ru is operated in Russia and must not receive the positions of
  // our users. The own Candle server goes here later.
  static const endpoints = [
    'https://overpass.openstreetmap.fr/api/interpreter',
    'https://overpass-api.de/api/interpreter',
  ];

  /// Longest wait for one endpoint before the next one is asked.
  static const timeout = Duration(seconds: 10);
}
