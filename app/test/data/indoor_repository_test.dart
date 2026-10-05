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

  test('good GPS outside any building: outdoors', () async {
    expect(await create().isProbablyIndoors(), isFalse);
    expect(overpass.queries.single, contains('[building]'));
  });

  test('a GPS point inside a building outline with good accuracy is not enough', () async {
    // standing outside next to a wall often puts the point into the outline
    overpass.result = const Result.ok([building]);
    expect(await create().isProbablyIndoors(), isFalse);
  });

  test('inside a building outline with mediocre accuracy: indoors', () async {
    overpass.result = const Result.ok([building]);
    location.accuracy = const Result.ok(20);
    expect(await create().isProbablyIndoors(), isTrue);
  });

  test('bad accuracy alone: indoors or poor reception', () async {
    location.accuracy = const Result.ok(40);
    expect(await create().isProbablyIndoors(), isTrue);
  });

  test('no GPS fix in time counts as bad accuracy', () async {
    location.accuracy = Result.error(Exception('timeout'));
    expect(await create().isProbablyIndoors(), isTrue);
  });

  test('without map data only the accuracy counts', () async {
    overpass.result = Result.error(Exception('offline'));
    expect(await create().isProbablyIndoors(), isFalse);
    location.accuracy = const Result.ok(40);
    expect(await create().isProbablyIndoors(), isTrue);
  });

  test('a point is inside a polygon only when it is', () {
    expect(isInsidePolygon(here, building.geometry), isTrue);
    expect(isInsidePolygon(const LatLng(52.5003, 13.4), building.geometry), isFalse);
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
