import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Loads POIs from OpenStreetMap via Overpass.
class PoiRepositoryRemote implements PoiRepository {
  PoiRepositoryRemote({required this._overpass});

  final OverpassClient _overpass;

  /// Overpass filters per category, see https://wiki.openstreetmap.org/wiki/Key:amenity
  static const Map<PoiCategory, List<String>> filters = {
    PoiCategory.crossings: ['node["highway"="crossing"]', 'way["highway"="crossing"]'],
    PoiCategory.bars: ['node["amenity"="bar"]', 'node["amenity"="nightclub"]'],
    PoiCategory.atms: ['node["amenity"="atm"]', 'node["amenity"="bank"]'],
    PoiCategory.restaurants: ['node["amenity"="restaurant"]'],
    PoiCategory.hospitals: ['node["amenity"="hospital"]'],
    PoiCategory.cafes: ['node["amenity"="cafe"]'],
    PoiCategory.busStations: ['node["amenity"="bus_station"]', 'node["highway"="bus_stop"]'],
    PoiCategory.taxis: ['node["amenity"="taxi"]'],
    PoiCategory.pharmacies: ['node["amenity"="pharmacy"]'],
    PoiCategory.audibleSignals: [
      'node["highway"="traffic_signals"]["traffic_signals:sound"="yes"]',
      'node["crossing"="traffic_signals"]["traffic_signals:sound"="yes"]',
    ],
    PoiCategory.publicToilets: ['node["amenity"="toilets"]'],
  };

  @override
  Future<Result<List<Poi>>> findNearby(
    Set<PoiCategory> categories,
    LatLng center, {
    int radiusInMeter = 2000,
  }) async {
    final around = '(around:$radiusInMeter,${center.latitude},${center.longitude})';
    final statements = [
      for (final category in categories) ...filters[category]!.map((f) => '$f$around;'),
    ].join('\n');
    final result = await _overpass.query('[out:json][timeout:25];\n(\n$statements\n);\nout center;');

    switch (result) {
      case Ok(:final value):
        return Result.ok(_toPois(value, center));
      case Error(:final error):
        return Result.error(error);
    }
  }

  List<Poi> _toPois(List<OverpassElement> elements, LatLng center) {
    final pois = elements.map(_toPoi).nonNulls.toList()
      ..sort((a, b) => calculateDistance(a.position, center)
          .compareTo(calculateDistance(b.position, center)));

    // The same shop is often mapped twice (node + building); keep the closest.
    // Unnamed places (crossings, signals) are distinct even if they share a kind.
    final seenNames = <String>{};
    return [
      for (final poi in pois)
        if (poi.kind != PoiKind.named || seenNames.add(poi.name)) poi,
    ];
  }

  Poi? _toPoi(OverpassElement element) {
    final tags = element.tags;
    final kind = _kindOf(tags);
    final name = tags['name'] ?? '';
    if (kind == PoiKind.named && name.isEmpty) return null;

    return Poi(
      id: element.id,
      kind: kind,
      position: LatLng(element.lat, element.lon),
      name: kind == PoiKind.named ? name : '',
      street: tags['addr:street'] ?? '',
      number: tags['addr:housenumber'] ?? '',
      zip: tags['addr:postcode'] ?? '',
      city: tags['addr:city'] ?? '',
    );
  }

  PoiKind _kindOf(Map<String, String> tags) {
    if (tags.containsKey('crossing') || tags['highway'] == 'crossing') {
      if (tags['crossing'] == 'traffic_signals') return PoiKind.crossingTrafficSignals;
      if (tags['crossing:markings'] == 'zebra') return PoiKind.crossingZebra;
      if (tags['crossing:island'] == 'yes') return PoiKind.crossingIsland;
      return PoiKind.crossingUnmarked;
    }
    if (tags['highway'] == 'traffic_signals') return PoiKind.audibleSignal;
    return PoiKind.named;
  }
}
