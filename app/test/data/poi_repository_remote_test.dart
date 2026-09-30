import 'package:candle/data/repositories/poi/poi_repository_remote.dart';
import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../fakes/fake_overpass_client.dart';

const center = LatLng(52.5163, 13.3777);

OverpassElement el(int id, double lat, Map<String, String> tags) =>
    OverpassElement(type: 'node', id: id, lat: lat, lon: 13.3777, tags: tags);

void main() {
  test('builds one around-statement per filter', () async {
    final overpass = FakeOverpassClient(const Result.ok([]));
    await PoiRepositoryRemote(overpass: overpass)
        .findNearby({PoiCategory.cafes}, center, radiusInMeter: 300);

    expect(overpass.queries.single, contains('node["amenity"="cafe"](around:300,52.5163,13.3777);'));
    expect(overpass.queries.single, contains('out center;'));
  });

  test('uses valid OSM tags for fixed categories', () {
    final f = PoiRepositoryRemote.filters;
    expect(f[PoiCategory.publicToilets], ['node["amenity"="toilets"]']);
    expect(f[PoiCategory.audibleSignals]!.first, contains('"traffic_signals:sound"="yes"'));
    expect(f.values.expand((e) => e).where((e) => e.contains('"station"') || e.contains('"payment"')),
        isEmpty);
  });

  test('maps crossings to kinds, drops unnamed places, sorts by distance', () async {
    final overpass = FakeOverpassClient(Result.ok([
      el(1, 52.5200, {'name': 'Far Café'}),
      el(2, 52.5170, {'name': 'Near Café'}),
      el(3, 52.5180, {}), // unnamed shop
      el(4, 52.5165, {'highway': 'crossing', 'crossing': 'traffic_signals'}),
      el(5, 52.5166, {'highway': 'crossing', 'crossing:markings': 'zebra'}),
      el(6, 52.5167, {'highway': 'crossing', 'crossing:island': 'yes'}),
      el(7, 52.5168, {'highway': 'crossing'}),
    ]));

    final result = await PoiRepositoryRemote(overpass: overpass).findNearby({PoiCategory.cafes}, center);
    final pois = (result as Ok<List<Poi>>).value;

    expect(pois.map((p) => p.id), [4, 5, 6, 7, 2, 1]);
    expect(pois.map((p) => p.kind).take(4), [
      PoiKind.crossingTrafficSignals,
      PoiKind.crossingZebra,
      PoiKind.crossingIsland,
      PoiKind.crossingUnmarked,
    ]);
  });

  test('keeps only the closest of equally named places, but every crossing', () async {
    final overpass = FakeOverpassClient(Result.ok([
      el(1, 52.5190, {'name': 'Café'}),
      el(2, 52.5170, {'name': 'Café'}),
      el(3, 52.5171, {'highway': 'crossing'}),
      el(4, 52.5172, {'highway': 'crossing'}),
    ]));

    final result = await PoiRepositoryRemote(overpass: overpass).findNearby({PoiCategory.cafes}, center);
    expect((result as Ok<List<Poi>>).value.map((p) => p.id), [2, 3, 4]);
  });

  test('passes errors through', () async {
    final overpass = FakeOverpassClient(Result.error(Exception('down')));
    final result = await PoiRepositoryRemote(overpass: overpass).findNearby({PoiCategory.cafes}, center);
    expect(result, isA<Error<List<Poi>>>());
  });
}
