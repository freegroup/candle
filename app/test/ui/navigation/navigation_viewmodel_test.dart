import 'package:candle/data/repositories/location/indoor_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/navigation/navigation_controller.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/ui/navigation/view_models/navigation_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';
import '../../fakes/fake_overpass_client.dart';

// A straight route north along 8° east, one point every ~111 m.
Route _northRoute() => Route(name: 'r', points: [
      for (var i = 0; i < 4; i++) NavigationPoint(coordinate: LatLng(50 + i * 0.001, 8), annotation: ''),
    ]);

class _FakeRouting implements RoutingRepository {
  @override
  Future<Result<Route>> walkingRoute(LatLng start, LatLng end) async => Result.ok(_northRoute());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CandleDatabase db;
  late LocationNoteRepository pins;
  late FakeLocationService location;
  late LocationNoteAnnouncer announcer;
  late NavigationController navigation;

  setUp(() async {
    db = CandleDatabase(NativeDatabase.memory());
    pins = LocationNoteRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(50, 8)));
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    announcer = LocationNoteAnnouncer(
        locationNoteRepository: pins, locationService: location, settingsRepository: settings);
    navigation = NavigationController(
      routingRepository: _FakeRouting(),
      locationNoteAnnouncer: announcer,
      locationService: location,
      compassService: FakeCompassService(),
      source: const LatLng(50, 8),
      target: const LatLng(50.003, 8),
    );
  });
  tearDown(() async {
    navigation.stop();
    announcer.dispose();
    await db.close();
  });

  NavigationViewModel create() => NavigationViewModel(
        navigationController: navigation,
        locationNoteRepository: pins,
        indoorRepository: IndoorRepository(
            locationService: location, overpassClient: FakeOverpassClient(const Result.ok([]))),
      );

  test('starts the navigation and redraws with every guidance', () async {
    final viewModel = create();
    var redraws = 0;
    viewModel.addListener(() => redraws++);
    final events = <NavigationEvent>[];
    viewModel.guidance.listen((guidance) => events.add(guidance.event));

    viewModel.start();
    await pumpEventQueue();
    expect(events, contains(NavigationEvent.routeCalculated));
    expect(viewModel.route, isNotNull);
    expect(viewModel.headingWaypoint?.coordinate.latitude, closeTo(50.001, 1e-9));
    expect(viewModel.currentGuidance.hasWaypoint, isTrue);
    expect(viewModel.currentGuidance.distanceToWaypoint, 111);
    // one for each guidance, one for the location notes
    expect(redraws, events.length + 1);
    viewModel.dispose();
  });

  test('shows the location notes on the map', () async {
    await pins.save(LocationNote(name: '', memo: 'Stairs', lat: 50.001, lon: 8));
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.locationNotes.map((note) => note.memo), ['Stairs']);
    viewModel.dispose();
  });

  test('checks once at the start whether the user is probably indoors', () async {
    location.accuracy = const Result.ok(40);
    final viewModel = create();
    await pumpEventQueue();
    expect((viewModel.checkIndoors.result! as Ok<bool>).value, isTrue);
    viewModel.dispose();
  });

  test('leaving right after the start is no error', () async {
    final viewModel = create();
    viewModel.dispose();
    await pumpEventQueue();
  });
}
