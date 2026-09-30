import 'package:latlong2/latlong.dart';

/// Categories offered on the "Explore" screen.
enum PoiCategory {
  crossings,
  bars,
  atms,
  restaurants,
  hospitals,
  cafes,
  busStations,
  taxis,
  pharmacies,
  audibleSignals,
  publicToilets,
}

extension PoiCategorySearch on PoiCategory {
  /// Crossings and traffic lights only matter close by, and there are far too
  /// many of them in a city (~1500 crossings within 2 km in Berlin Mitte).
  int get searchRadiusInMeter => switch (this) {
        PoiCategory.crossings || PoiCategory.audibleSignals => 500,
        _ => 2000,
      };
}

/// What kind of place a [Poi] is. Places without an OSM name (crossings,
/// traffic lights) get a generated, localized name from their kind.
enum PoiKind {
  named,
  crossingTrafficSignals,
  crossingZebra,
  crossingIsland,
  crossingUnmarked,
  audibleSignal,
}

/// A point of interest near the user.
final class Poi {
  const Poi({
    required this.id,
    required this.kind,
    required this.position,
    this.name = '',
    this.street = '',
    this.number = '',
    this.zip = '',
    this.city = '',
  });

  final int id;
  final PoiKind kind;
  final LatLng position;

  /// OSM name; empty unless [kind] is [PoiKind.named].
  final String name;
  final String street;
  final String number;
  final String zip;
  final String city;

  bool get hasAddress => street.isNotEmpty && number.isNotEmpty && city.isNotEmpty;
}
