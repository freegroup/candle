import 'package:candle/data/repositories/location/indoor_repository.dart';
import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../fakes/fake_location_service.dart';
import '../fakes/fake_overpass_client.dart';

const here = LatLng(52.5, 13.4);

// A square of ~22 m around [here].
const building = OverpassElement(
  type: 'way',
  id: 1,
  lat: 52.4999,
  lon: 13.3998,
  tags: {'building': 'yes'},
  geometry: [
    LatLng(52.4999, 13.3998),
    LatLng(52.4999, 13.4002),
    LatLng(52.5001, 13.4002),
    LatLng(52.5001, 13.3998),
    LatLng(52.4999, 13.3998),
  ],
);

void main() {
  late FakeLocationService location;
  late FakeOverpassClient overpass;

  IndoorRepository create() => IndoorRepository(locationService: location, overpassClient: overpass);

  setUp(() {
    location = FakeLocationService(const Result.ok(here));
    overpass = FakeOverpassClient(const Result.ok([]));
  });

  group('1. poor reception', () {
    test('accuracy worse than the limit: indoors or poor reception', () async {
      location.accuracy = const Result.ok(40);
      expect(await create().isProbablyIndoors(), isTrue);
    });

    test('no GPS fix in time counts as poor reception', () async {
      location.accuracy = Result.error(Exception('timeout'));
      expect(await create().isProbablyIndoors(), isTrue);
    });

    test('without map data it is the only case', () async {
      overpass.result = Result.error(Exception('offline'));
      expect(await create().isProbablyIndoors(), isFalse);
      location.accuracy = const Result.ok(40);
      expect(await create().isProbablyIndoors(), isTrue);
    });
  });

  group('2. inside a building outline, away from its walls', () {
    test('~11 m from every wall: indoors', () async {
      overpass.result = const Result.ok([building]);
      expect(await create().isProbablyIndoors(), isTrue);
      expect(overpass.queries.single, contains('[building]'));
    });

    test('the accuracy plays no part here', () async {
      overpass.result = const Result.ok([building]);
      location.accuracy = const Result.ok(15);
      expect(await create().isProbablyIndoors(), isTrue);
    });

    test('~4 m from a wall is still inside', () async {
      overpass.result = const Result.ok([building]);
      location.position = const Result.ok(LatLng(52.500064, 13.4));
      expect(await create().isProbablyIndoors(), isTrue);
    });
  });

  group('3. outdoors', () {
    test('good GPS outside any building', () async {
      expect(await create().isProbablyIndoors(), isFalse);
    });

    test('inside the outline but less than 2 m from a wall, e.g. on the pavement', () async {
      overpass.result = const Result.ok([building]);
      location.position = const Result.ok(LatLng(52.500092, 13.4)); // ~1 m from the north wall
      expect(await create().isProbablyIndoors(), isFalse);
    });
  });

  test('a point is inside a polygon only when it is', () {
    expect(isInsidePolygon(here, building.geometry), isTrue);
    expect(isInsidePolygon(const LatLng(52.5003, 13.4), building.geometry), isFalse);
  });

  test('with an inset, a point close to an edge does not count as inside', () {
    const nearEdge = LatLng(52.500092, 13.4); // ~1 m from the north edge
    expect(isInsidePolygon(nearEdge, building.geometry), isTrue);
    expect(isInsidePolygon(nearEdge, building.geometry, inset: 2), isFalse);
    expect(isInsidePolygon(here, building.geometry, inset: 2), isTrue);
  });

  test('ways with geometry are parsed with their outline', () {
    final element = OverpassElement.fromJson({
      'type': 'way',
      'id': 7,
      'tags': {'building': 'yes'},
      'geometry': [
        {'lat': 52.4999, 'lon': 13.3998},
        {'lat': 52.5001, 'lon': 13.4002},
      ],
    });
    expect(element?.geometry, [const LatLng(52.4999, 13.3998), const LatLng(52.5001, 13.4002)]);
    expect(element?.lat, 52.4999);
  });
}
