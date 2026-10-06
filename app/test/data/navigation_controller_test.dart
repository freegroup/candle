import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/navigation/navigation_controller.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_compass_service.dart';
import '../fakes/fake_location_service.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  late CandleDatabase db;
  late LocationNoteRepository pins;
  late FakeLocationService location;
  late FakeCompassService compass;
  late _FakeRouting routing;
  late SettingsRepository settings;
  late LocationNoteAnnouncer announcer;

  setUp(() async {
    db = CandleDatabase(NativeDatabase.memory());
    pins = LocationNoteRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(50, 8)));
    compass = FakeCompassService();
    routing = _FakeRouting();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    await settings.setEnabled(Setting.locationNotesAlways, false);
    announcer = LocationNoteAnnouncer(
        locationNoteRepository: pins, locationService: location, settingsRepository: settings);
  });
  tearDown(() async {
    announcer.dispose();
    await db.close();
  });

  // All guidance of the navigation created last, and its events without the plain updates.
  late List<NavigationGuidance> guidance;
  late List<NavigationEvent> events;

  // A started navigation; its guidance is collected from the start on.
  NavigationController create({Route? route, LatLng source = const LatLng(50, 8)}) {
    final navigation = NavigationController(
      routingRepository: routing,
      locationNoteAnnouncer: announcer,
      locationService: location,
      compassService: compass,
      source: source,
      target: const LatLng(50.003, 8),
      route: route,
    );
    guidance = [];
    events = [];
    navigation.guidance.listen((next) {
      guidance.add(next);
      if (next.event != NavigationEvent.update) events.add(next.event);
    });
    navigation.start();
    return navigation;
  }

  Future<void> walkTo(double lat, [double lon = 8]) async {
    location.controller.add(LatLng(lat, lon));
    await pumpEventQueue();
  }

  test('calculates a route and heads to its next waypoint', () async {
    final navigation = create();
    await pumpEventQueue();
    expect(routing.requests, hasLength(1));
    expect(navigation.headingWaypoint?.coordinate.latitude, closeTo(50.001, 1e-9));
    expect(navigation.turnWaypoint?.coordinate.latitude, closeTo(50.002, 1e-9));

    compass.headingController.add(0);
    await pumpEventQueue();
    expect(navigation.isAligned, isTrue);
    compass.headingController.add(90);
    await pumpEventQueue();
    expect(navigation.isAligned, isFalse);
    navigation.stop();
  });

  test('moves on to the next waypoint and reaches the target', () async {
    final navigation = create(route: _northRoute(50, 4));
    await pumpEventQueue();
    expect(routing.requests, isEmpty);

    await walkTo(50.001);
    expect(navigation.headingWaypoint?.coordinate.latitude, closeTo(50.002, 1e-9));
    expect(navigation.targetReached, isFalse);

    await walkTo(50.003);
    expect(navigation.targetReached, isTrue);
    navigation.stop();
  });

  test('leaving the route calculates a new one that is followed from its start', () async {
    final navigation = create(route: _northRoute(50, 4));
    await pumpEventQueue();
    await walkTo(50.002);
    expect(navigation.headingWaypoint?.coordinate.latitude, closeTo(50.003, 1e-9));

    // ~140 m east of the route
    await walkTo(50.002, 8.002);
    expect(routing.requests, hasLength(1));
    // the new route starts here; its first waypoint is the next one, not one far down the list
    expect(navigation.headingWaypoint?.coordinate.latitude, closeTo(50.003, 1e-9));
    expect(navigation.headingWaypoint?.coordinate.longitude, 8.002);
    navigation.stop();
  });

  test('a new route that starts away from the user is not calculated again at once', () async {
    routing.answer = (start) => Result.ok(_northRoute(start.latitude, 4, start.longitude + 0.01));
    final navigation = create();
    await pumpEventQueue();
    expect(routing.requests, hasLength(1));

    await walkTo(50.0001);
    expect(routing.requests, hasLength(2));
    navigation.stop();
  });

  test('reports a failed route calculation', () async {
    routing.answer = (_) => Result.error(Exception('offline'));
    final navigation = create();
    await pumpEventQueue();
    expect(navigation.route, isNull);
    expect(navigation.routeFailed, isTrue);
    navigation.stop();
  });

  test('location notes are reported during the navigation only', () async {
    await pins.save(LocationNote(name: '', memo: 'Stairs', lat: 50.001, lon: 8.00005));
    final reached = <String>[];
    announcer.reached.listen((note) => reached.add(note.memo));

    final navigation = create(route: _northRoute(50, 4));
    await pumpEventQueue();
    await walkTo(50.001);
    expect(reached, ['Stairs']);

    navigation.stop();
    await walkTo(50);
    await walkTo(50.001);
    expect(reached, ['Stairs']);
  });

  test('reports the start, the route and whether the phone points to the waypoint', () async {
    final navigation = create();
    await pumpEventQueue();
    // the phone points north, like the route
    expect(events, [NavigationEvent.started, NavigationEvent.routeCalculated, NavigationEvent.aligned]);

    compass.headingController.add(90);
    await pumpEventQueue();
    compass.headingController.add(100);
    await pumpEventQueue();
    expect(events.last, NavigationEvent.notAligned);
    expect(events.where((event) => event == NavigationEvent.notAligned), hasLength(1));

    navigation.stop();
    await pumpEventQueue();
    expect(events.last, NavigationEvent.stopped);
  });

  test('reports passed waypoints and the target', () async {
    final navigation = create(route: _northRoute(50, 4));
    await walkTo(50.001);
    await walkTo(50.002);
    await walkTo(50.003);
    expect(events.where((event) => event == NavigationEvent.waypointPassed), hasLength(3));
    expect(events.last, NavigationEvent.targetReached);
    navigation.stop();
  });

  test('the guidance tells the way to the next waypoint', () async {
    // north, then east at the second point
    final route = Route(name: 'r', points: [
      NavigationPoint(coordinate: const LatLng(50, 8), annotation: ''),
      NavigationPoint(coordinate: const LatLng(50.001, 8), annotation: ''),
      NavigationPoint(coordinate: const LatLng(50.001, 8.002), annotation: ''),
    ]);
    final navigation = create(route: route);
    compass.headingController.add(350);
    await pumpEventQueue();

    expect(guidance.last.hasWaypoint, isTrue);
    expect(guidance.last.distanceToWaypoint, 111);
    // turns right: east along the great circle starts at 89.99°, calculateNorthBearing cuts it to 89
    expect(guidance.last.turnAngle, -89);
    // 10° to the right, not 350° to the left
    expect(guidance.last.waypointRotation, 10);
    navigation.stop();
  });

  test('leaving the route is reported once, also while the user stays away', () async {
    // the new route starts away from the user, so they stay off the route
    routing.answer = (start) => Result.ok(_northRoute(start.latitude, 4, start.longitude + 0.01));
    final navigation = create(route: _northRoute(50, 4));
    await walkTo(50.001, 8.002);
    await walkTo(50.0011, 8.002);
    expect(events.where((event) => event == NavigationEvent.offRoute), hasLength(1));
    expect(events, contains(NavigationEvent.routeCalculated));
    navigation.stop();
  });

  test('a failing route calculation is reported once', () async {
    routing.answer = (_) => Result.error(Exception('offline'));
    final navigation = create();
    await pumpEventQueue();
    await walkTo(50.0001);
    expect(routing.requests, hasLength(2));
    expect(events.where((event) => event == NavigationEvent.routeFailed), hasLength(1));
    navigation.stop();
  });

  test('stopping right after the start is no error', () async {
    final navigation = create();
    navigation.stop();
    await pumpEventQueue();
  });
}
