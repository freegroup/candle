import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/ui/navigation/view_models/navigation_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';

// A straight route north along 8° east, one point every ~111 m.
Route _northRoute(double fromLat, int count, [double lon = 8]) => Route(name: 'r', points: [
      for (var i = 0; i < count; i++)
        NavigationPoint(coordinate: LatLng(fromLat + i * 0.001, lon), annotation: ''),
    ]);

class _FakeRouting implements RoutingRepository {
  final requests = <LatLng>[];
  Result<Route> Function(LatLng start) answer = (start) => Result.ok(_northRoute(start.latitude, 4, start.longitude));

  @override
  Future<Result<Route>> walkingRoute(LatLng start, LatLng end) async {
    requests.add(start);
    return answer(start);
  }
}

void main() {
  late CandleDatabase db;
  late LocationNoteRepository pins;
  late FakeLocationService location;
  late FakeCompassService compass;
  late _FakeRouting routing;

  setUp(() {
    db = CandleDatabase(NativeDatabase.memory());
    pins = LocationNoteRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(50, 8)));
    compass = FakeCompassService();
    routing = _FakeRouting();
  });
  tearDown(() => db.close());

  NavigationViewModel create({Route? route, LatLng source = const LatLng(50, 8)}) =>
      NavigationViewModel(
        routingRepository: routing,
        locationNoteRepository: pins,
        locationService: location,
        compassService: compass,
        source: source,
        target: const LatLng(50.003, 8),
        route: route,
      );

  Future<void> walkTo(double lat, [double lon = 8]) async {
    location.controller.add(LatLng(lat, lon));
    await pumpEventQueue();
  }

  test('calculates a route and heads to its next waypoint', () async {
    final viewModel = create();
    await pumpEventQueue();
    expect(routing.requests, hasLength(1));
    expect(viewModel.headingWaypoint?.coordinate.latitude, closeTo(50.001, 1e-9));
    expect(viewModel.turnWaypoint?.coordinate.latitude, closeTo(50.002, 1e-9));

    compass.headingController.add(0);
    await pumpEventQueue();
    expect(viewModel.isAligned, isTrue);
    compass.headingController.add(90);
    await pumpEventQueue();
    expect(viewModel.isAligned, isFalse);
    viewModel.dispose();
  });

  test('moves on to the next waypoint and reaches the target', () async {
    final viewModel = create(route: _northRoute(50, 4));
    await pumpEventQueue();
    expect(routing.requests, isEmpty);

    await walkTo(50.001);
    expect(viewModel.headingWaypoint?.coordinate.latitude, closeTo(50.002, 1e-9));
    expect(viewModel.targetReached, isFalse);

    await walkTo(50.003);
    expect(viewModel.targetReached, isTrue);
    viewModel.dispose();
  });

  test('leaving the route calculates a new one that is followed from its start', () async {
    final viewModel = create(route: _northRoute(50, 4));
    await pumpEventQueue();
    await walkTo(50.002);
    expect(viewModel.headingWaypoint?.coordinate.latitude, closeTo(50.003, 1e-9));

    // ~140 m east of the route
    await walkTo(50.002, 8.002);
    expect(routing.requests, hasLength(1));
    // the new route starts here; its first waypoint is the next one, not one far down the list
    expect(viewModel.headingWaypoint?.coordinate.latitude, closeTo(50.003, 1e-9));
    expect(viewModel.headingWaypoint?.coordinate.longitude, 8.002);
    viewModel.dispose();
  });

  test('a new route that starts away from the user is not calculated again at once', () async {
    routing.answer = (start) => Result.ok(_northRoute(start.latitude, 4, start.longitude + 0.01));
    final viewModel = create();
    await pumpEventQueue();
    expect(routing.requests, hasLength(1));

    await walkTo(50.0001);
    expect(routing.requests, hasLength(2));
    viewModel.dispose();
  });

  test('reports a failed route calculation', () async {
    routing.answer = (_) => Result.error(Exception('offline'));
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.route, isNull);
    expect(viewModel.routeFailed, isTrue);
    viewModel.dispose();
  });

  test('a location note is announced once, and again after the user was 50 m away', () async {
    await pins.save(LocationNote(name: '', memo: 'Stairs', lat: 50.001, lon: 8.00005));
    final viewModel = create(route: _northRoute(50, 4));
    final reached = <String>[];
    viewModel.reachedLocationNotes.listen((note) => reached.add(note.memo));
    await pumpEventQueue();
    expect(reached, isEmpty);

    await walkTo(50.001);
    expect(reached, ['Stairs']);

    // staying close or only ~33 m away does not repeat it
    await walkTo(50.00102);
    await walkTo(50.0007);
    await walkTo(50.001);
    expect(reached, ['Stairs']);

    // ~111 m away resets it
    await walkTo(50);
    await walkTo(50.001);
    expect(reached, ['Stairs', 'Stairs']);
    viewModel.dispose();
  });
}
