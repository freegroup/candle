import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/repositories/recording/recording_repository.dart';
import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/repositories/location/indoor_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/services/accessibility/accessibility_service.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/tips/tips_repository.dart';
import 'package:candle/data/repositories/wikipedia/wikipedia_repository.dart';
import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/domain/models/tip.dart';
import 'package:candle/ui/tips/widgets/tip_screen.dart';
import 'package:candle/ui/tips/widgets/tips_screen.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/route.dart' as model;
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/about/widgets/about_screen.dart';
import 'package:candle/ui/compass/widgets/heading_compass_screen.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/home/widgets/home_screen.dart';
import 'package:candle/ui/import/widgets/import_location_screen.dart';
import 'package:candle/ui/import/widgets/import_location_note_screen.dart';
import 'package:candle/ui/onboarding/widgets/welcome_screen.dart';
import 'package:candle/ui/locations/widgets/address_search_screen.dart';
import 'package:candle/ui/locations/widgets/location_edit_screen.dart';
import 'package:candle/ui/locations/widgets/locations_screen.dart';
import 'package:candle/ui/radar/widgets/radar_screen.dart';
import 'package:candle/ui/recording/widgets/recording_screen.dart';
import 'package:candle/ui/routes/widgets/route_edit_screen.dart';
import 'package:candle/ui/routes/widgets/routes_screen.dart';
import 'package:candle/ui/settings/widgets/settings_screen.dart';
import 'package:candle/ui/location_notes/widgets/location_note_edit_screen.dart';
import 'package:candle/ui/location_notes/widgets/location_notes_screen.dart';
import 'package:candle/ui/wikipedia/widgets/wikipedia_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_overpass_client.dart';
import '../fakes/fake_compass_service.dart';
import '../fakes/fake_geocoding_repository.dart';
import '../fakes/fake_location_service.dart';
import '../fakes/fake_poi_repository.dart';
import '../fakes/fake_tips_service.dart';

const _here = LatLng(52.5163, 13.3777);
final _address = LocationAddress(
    name: 'Home', formattedAddress: 'Main Street 1', street: 'Main Street', number: '1',
    zip: '', city: 'Town', country: '', lat: 52.5163, lon: 13.3777);

class _NoShare implements ShareService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Permissions implements PermissionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Wikipedia implements WikipediaRepository {
  @override
  Future<Result<List<ArticleRef>>> nearby(LatLng position) async =>
      const Result.ok([]);

  @override
  Future<Result<ArticleSummary>> summary(ArticleRef article) async =>
      Result.error(Exception('unused'));
}

/// Builds every screen once with the app's way of creating its view model.
/// Catches mistakes that only show at runtime in debug builds, such as reading
/// inherited widgets in a provider's create callback.
void main() {
  late CandleDatabase db;
  late SettingsRepository settings;

  setUp(() async {
    db = CandleDatabase(NativeDatabase.memory());
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    PackageInfo.setMockInitialValues(
        appName: 'Candle', packageName: 'x', version: '1.0.0', buildNumber: '1', buildSignature: '');
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget Function() screen) async {
    // a phone in portrait with a large system font, as many visually impaired users have
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final location = FakeLocationService(const Result.ok(_here));
    final routes = RouteRepository(database: db);
    final notes = LocationNoteRepository(database: db);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider<LocationService>.value(value: location),
        Provider.value(
          value: IndoorRepository(
              locationService: location, overpassClient: FakeOverpassClient(const Result.ok([]))),
        ),
        Provider<CompassService>.value(value: FakeCompassService()),
        Provider<GeocodingRepository>.value(value: FakeGeocodingRepository()..address = _address),
        Provider<PoiRepository>.value(value: FakePoiRepository(const Result.ok([]))),
        Provider<WikipediaRepository>.value(value: _Wikipedia()),
        Provider<ShareService>.value(value: _NoShare()),
        ChangeNotifierProvider(
          create: (_) => TipsRepository(
            tipsService: FakeTipsService(),
            settingsRepository: settings,
            languageService: LanguageService(preferredLocales: () => const [Locale('de')]),
          ),
        ),
        Provider.value(value: AccessibilityService()),
        Provider<PermissionService>.value(value: _Permissions()),
        Provider.value(value: VibrationService(settingsRepository: settings)),
        Provider.value(value: LocationRepository(database: db)),
        Provider.value(value: notes),
        Provider(
          create: (_) => LocationNoteAnnouncer(
              locationNoteRepository: notes, locationService: location, settingsRepository: settings),
          dispose: (_, announcer) => announcer.dispose(),
        ),
        Provider.value(value: routes),
        ChangeNotifierProvider(
          create: (_) => RecordingRepository(routeRepository: routes, locationService: location),
        ),
      ],
      child: MaterialApp(
        theme: CThemeData.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (_) => screen()),
      ),
    ));
    await tester.pump();
    // let delayed announcements and debounce timers run out
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  final screens = <String, Widget Function()>{
    'home': buildHomeScreen,
    'welcome': () => WelcomeScreen(onContinue: () {}, onSettings: () {}),
    'import location': () => buildImportLocationScreen(_address),
    'import location note': () =>
        buildImportLocationNoteScreen(LocationNote(name: '', memo: 'Stairs after the door', lat: _here.latitude, lon: _here.longitude)),
    'about': buildAboutScreen,
    'settings': buildSettingsScreen,
    'heading compass': buildHeadingCompassScreen,
    'target compass': () => buildTargetCompassScreen(target: _here, targetName: 'Home'),
    'locations': buildLocationsScreen,
    'location edit': () => buildLocationEditScreen(_address),
    'address search': () => buildAddressSearchScreen(query: 'Main'),
    'voice pins': buildLocationNotesScreen,
    'voice pin edit': () =>
        buildLocationNoteEditScreen(LocationNote(name: '', memo: '', lat: _here.latitude, lon: _here.longitude)),
    'routes': buildRoutesScreen,
    'route edit': () => buildRouteEditScreen(model.Route(name: 'Walk', points: [])),
    'recording': buildRecordingScreen,
    'radar': buildRadarScreen,
    'wikipedia': buildWikipediaScreen,
    'tips': buildTipsScreen,
    'tip': () => const TipScreen(
        tip: Tip(id: 'notes', title: 'Was sind Ortsnotizen?', text: 'Ein Hinweis.\n\nNoch einer.', read: false)),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} screen builds', (tester) => pump(tester, entry.value));
  }
}
