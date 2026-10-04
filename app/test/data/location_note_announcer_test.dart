import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_location_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late CandleDatabase db;
  late LocationNoteRepository notes;
  late FakeLocationService location;
  late SettingsRepository settings;
  late LocationNoteAnnouncer announcer;
  late List<String> reached;

  setUp(() async {
    db = CandleDatabase(NativeDatabase.memory());
    notes = LocationNoteRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(50, 8)));
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    await notes.save(LocationNote(name: '', memo: 'Stairs', lat: 50.001, lon: 8));
    reached = [];
  });

  tearDown(() async {
    announcer.dispose();
    await db.close();
  });

  void create() {
    announcer = LocationNoteAnnouncer(
        locationNoteRepository: notes, locationService: location, settingsRepository: settings);
    announcer.reached.listen((note) => reached.add(note.memo));
  }

  Future<void> walkTo(double lat) async {
    await pumpEventQueue();
    location.controller.add(LatLng(lat, 8));
    await pumpEventQueue();
  }

  test('by default a note is reported anywhere, once until the user was 50 m away', () async {
    create();
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
  });

  test('only during a navigation if the user turned "always" off', () async {
    await settings.setEnabled(Setting.locationNotesAlways, false);
    create();
    await walkTo(50.001);
    expect(reached, isEmpty);

    announcer.startNavigation();
    await walkTo(50.001);
    expect(reached, ['Stairs']);

    announcer.stopNavigation();
    await settings.setEnabled(Setting.locationNotesAlways, true);
    await walkTo(50);
    await walkTo(50.001);
    expect(reached, ['Stairs', 'Stairs']);
  });

  test('a new navigation reports a note again', () async {
    create();
    await walkTo(50.001);
    announcer.startNavigation();
    await walkTo(50.001);
    expect(reached, ['Stairs', 'Stairs']);
    announcer.stopNavigation();
  });

  test('nothing is reported while paused; notes around the user then count as heard', () async {
    create();
    announcer.pause();
    await walkTo(50.001);
    // a note added during the pause right here
    await notes.save(LocationNote(name: '', memo: 'Bench', lat: 50.00101, lon: 8));
    expect(reached, isEmpty);

    announcer.resume();
    await walkTo(50.001);
    expect(reached, isEmpty);

    // ~111 m away and back: both come again
    await walkTo(50);
    await walkTo(50.001);
    expect(reached, unorderedEquals(['Stairs']));
    await walkTo(50.00101);
    expect(reached, unorderedEquals(['Stairs', 'Bench']));
  });

  test('pauses can overlap; reporting goes on after the last one ends', () async {
    create();
    announcer
      ..pause()
      ..pause()
      ..resume();
    await walkTo(50.001);
    expect(reached, isEmpty);

    announcer.resume();
    await walkTo(50);
    await walkTo(50.001);
    expect(reached, ['Stairs']);
  });

  test('nothing is reported while Candle is in the background', () async {
    create();
    // the platform reports the steps one by one
    void show() => binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    addTearDown(show);
    await walkTo(50.001);
    expect(reached, isEmpty);

    show();
    await walkTo(50.001);
    expect(reached, ['Stairs']);
  });
}
