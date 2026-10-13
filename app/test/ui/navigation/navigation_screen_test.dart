import 'dart:async';

import 'package:candle/data/repositories/location/indoor_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart' as model;
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/navigation/announcers/announcer.dart';
import 'package:candle/ui/navigation/widgets/navigation_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';
import '../../fakes/fake_overpass_client.dart';

const _start = LatLng(50, 8);

// A straight route north along 8° east, one point every ~111 m.
model.Route _northRoute() => model.Route(name: 'r', points: [
      for (var i = 0; i < 4; i++) NavigationPoint(coordinate: LatLng(50 + i * 0.001, 8), annotation: ''),
    ]);

class _FakeRouting implements RoutingRepository {
  @override
  Future<Result<model.Route>> walkingRoute(LatLng start, LatLng end) async => Result.ok(_northRoute());
}

void main() {
  late CandleDatabase db;
  late SettingsRepository settings;

  setUp(() async {
    db = CandleDatabase(NativeDatabase.memory());
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    // no motor and no audio player in tests
    VibrationService.recorder = (duration, repeat, pattern) {};
  });
  tearDown(() async {
    VibrationService.recorder = null;
    await db.close();
  });

  testWidgets('leaving the navigation stops what is said', (tester) async {
    // TTS.interrupt stops the screen reader over this channel
    var interrupts = 0;
    const interruptChannel = MethodChannel('candle/accessibility');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(interruptChannel, (call) async {
      if (call.method == 'interrupt') interrupts++;
      return null;
    });
    addTearDown(() =>
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(interruptChannel, null));

    final location = FakeLocationService(const Result.ok(_start));
    final notes = LocationNoteRepository(database: db);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider<RoutingRepository>.value(value: _FakeRouting()),
        Provider<LocationService>.value(value: location),
        Provider<CompassService>.value(value: FakeCompassService()),
        Provider.value(value: notes),
        Provider.value(
          value: IndoorRepository(
              locationService: location, overpassClient: FakeOverpassClient(const Result.ok([]))),
        ),
        Provider(
          create: (_) => LocationNoteAnnouncer(
              locationNoteRepository: notes, locationService: location, settingsRepository: settings),
          dispose: (_, announcer) => announcer.dispose(),
        ),
        Provider(create: (_) => NavigationAnnouncer(settingsRepository: settings)),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        theme: CThemeData.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('Start')),
      ),
    ));

    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) =>
          buildNavigationScreen(source: _start, target: const LatLng(50.003, 8), route: _northRoute()),
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(interrupts, 0);

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(interrupts, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
