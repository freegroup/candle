import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

LocationAddress _location(String name, {int? id}) => LocationAddress(
      id: id,
      name: name,
      formattedAddress: 'Main Street 1',
      street: 'Main Street',
      number: '1',
      zip: '12345',
      city: 'Town',
      country: 'DE',
      lat: 49.1,
      lon: 8.4,
    );

NavigationPoint _point(double lat) =>
    NavigationPoint(coordinate: LatLng(lat, 8.4), annotation: '');

int _id(Result<int> result) => (result as Ok<int>).value;

void main() {
  late CandleDatabase db;

  setUp(() => db = CandleDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('LocationRepository', () {
    test('saves, updates and deletes, ordered by name', () async {
      final repository = LocationRepository(database: db);

      final bakery = _id(await repository.save(_location('Bakery')));
      await repository.save(_location('Apotheke'));
      expect((await repository.watchAll().first).map((l) => l.name), ['Apotheke', 'Bakery']);

      expect(_id(await repository.save(_location('Zoo', id: bakery))), bakery);
      final all = await repository.watchAll().first;
      expect(all.map((l) => l.name), ['Apotheke', 'Zoo']);
      expect(all.last, _location('Zoo', id: bakery));

      await repository.delete(bakery);
      expect((await repository.watchAll().first).map((l) => l.name), ['Apotheke']);
    });
  });

  group('LocationNoteRepository', () {
    test('lists the newest pin first and keeps the update id', () async {
      final repository = LocationNoteRepository(database: db);
      LocationNote pin(String name, DateTime created, {int? id}) =>
          LocationNote(id: id, name: name, memo: 'memo', lat: 1, lon: 2, created: created);

      final old = _id(await repository.save(pin('old', DateTime(2024))));
      await repository.save(pin('new', DateTime(2025)));
      expect((await repository.watchAll().first).map((p) => p.name), ['new', 'old']);

      expect(_id(await repository.save(pin('renamed', DateTime(2024), id: old))), old);
      expect((await repository.watchAll().first).map((p) => p.name), ['new', 'renamed']);

      await repository.delete(old);
      expect((await repository.watchAll().first).map((p) => p.name), ['new']);
    });
  });

  group('RouteRepository', () {
    test('keeps the point order and replaces points on update', () async {
      final repository = RouteRepository(database: db);

      final id = _id(await repository.save(Route(name: 'Work', points: [_point(1), _point(2)])));
      var route = (await repository.watch(id).first)!;
      expect(route.points.map((p) => p.coordinate.latitude), [1, 2]);

      await repository.save(route.copyWith(name: 'Office', points: [_point(3)]));
      route = (await repository.watch(id).first)!;
      expect(route.name, 'Office');
      expect(route.points.map((p) => p.coordinate.latitude), [3]);
    });

    test('appends recorded points and notifies watchers', () async {
      final repository = RouteRepository(database: db);
      final id = _id(await repository.save(Route(name: 'Walk', points: [])));

      final updates = repository.watch(id).map((r) => r!.points.length);
      final expectation = expectLater(updates, emitsInOrder([0, 1, 2]));
      await Future<void>.delayed(Duration.zero);
      await repository.addPoint(id, _point(1));
      await Future<void>.delayed(Duration.zero);
      await repository.addPoint(id, _point(2));
      await expectation;

      final route = (await repository.watch(id).first)!;
      expect(route.points.map((p) => p.coordinate.latitude), [1, 2]);
    });

    test('deleting a route deletes its points', () async {
      final repository = RouteRepository(database: db);
      final id = _id(await repository.save(Route(name: 'Walk', points: [_point(1)])));

      await repository.delete(id);
      expect(await repository.watchAll().first, isEmpty);
      expect(await db.select(db.routePoints).get(), isEmpty);
    });

    test('route names are unique', () async {
      final repository = RouteRepository(database: db);
      await repository.save(Route(name: 'Walk', points: []));
      expect(await repository.save(Route(name: 'Walk', points: [])), isA<Error<int>>());
    });
  });
}
