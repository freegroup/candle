import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/radar/view_models/radar_viewmodel.dart';
import 'package:candle/ui/radar/widgets/radar_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_geocoding_repository.dart';
import '../../fakes/fake_location_service.dart';
import '../../fakes/fake_poi_repository.dart';

const here = LatLng(52.5163, 13.3777);
const cafe = Poi(
  id: 1,
  kind: PoiKind.named,
  name: 'Café Einstein',
  street: 'Unter den Linden',
  number: '42',
  city: 'Berlin',
  position: LatLng(52.5170, 13.3777),
);
const signal = Poi(id: 2, kind: PoiKind.audibleSignal, position: LatLng(52.5180, 13.3777));

void main() {
  late FakePoiRepository repository;
  late FakeCompassService compass;
  late RadarViewModel viewModel;
  late List<String> announcements;
  // The semantics nodes the screen reader focus was moved to.
  late List<int> focusedNodes;
  late int vibrations;
  late SettingsRepository settings;
  late int interruptions;

  Future<void> pumpScreen(WidgetTester tester) async {
    viewModel = RadarViewModel(
      poiRepository: repository,
      locationService: FakeLocationService(const Result.ok(here)),
      geocodingRepository: FakeGeocodingRepository(),
      compassService: compass,
    );
    // the radar reads the vibration setting from the providers
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        theme: CThemeData.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RadarScreen(viewModel: viewModel),
      ),
    ));
    await tester.pump();
    // let the delayed screen announcement run out
    await tester.pump(const Duration(seconds: 4));
  }

  Future<void> point(WidgetTester tester, double heading) async {
    compass.headingController.add(heading);
    await tester.pump();
    await tester.pump();
  }

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    VibrationService.recorder = (duration, repeat, pattern) => vibrations++;
    repository = FakePoiRepository(const Result.ok([cafe, signal]));
    compass = FakeCompassService();
    announcements = [];
    focusedNodes = [];
    vibrations = 0;
    interruptions = 0;
  });

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (Object? message) async {
        final map = message! as Map<Object?, Object?>;
        final data = map['data']! as Map<Object?, Object?>;
        if (data['message'] case final String text) announcements.add(text);
        if (map['type'] == 'focus') focusedNodes.add(map['nodeId']! as int);
        return null;
      },
    );
    // TTS.interrupt stops the screen reader over this channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('candle/accessibility'), (call) async {
      if (call.method == 'interrupt') interruptions++;
      return null;
    });
  });

  tearDown(() => viewModel.dispose());
  tearDown(() => VibrationService.recorder = null);

  testWidgets('lists the places of the direction and announces it', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Café Einstein'), findsNothing);

    await point(tester, 3);

    expect(find.text('Café Einstein'), findsOneWidget);
    expect(find.text('Unter den Linden 42, Berlin'), findsOneWidget);
    expect(find.text('78 m'), findsOneWidget);
    expect(vibrations, 1);
    expect(interruptions, 1);
    expect(announcements.last, 'Norden, 2 nahegelegene Orte.');
  });

  testWidgets('announces the true compass direction (east is not west)', (tester) async {
    await pumpScreen(tester);

    await point(tester, 88);

    expect(announcements.last, startsWith('Osten'));
    expect(find.text('Café Einstein'), findsNothing);
  });

  testWidgets('announces a direction once until the phone leaves it', (tester) async {
    await pumpScreen(tester);

    await point(tester, 0);
    await point(tester, 5);
    expect(vibrations, 1);

    await point(tester, 20);
    await point(tester, 0);
    expect(vibrations, 2);
  });

  testWidgets('offers to save and to share a place as screen reader actions', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    await point(tester, 0);

    final actions = <String>[];
    SemanticsNode? current = tester.getSemantics(find.text('Café Einstein'));
    while (current != null && actions.isEmpty) {
      final ids = current.getSemanticsData().customSemanticsActionIds ?? [];
      actions.addAll(ids.map((id) => CustomSemanticsAction.getAction(id)!.label!));
      current = current.parent;
    }
    expect(actions, unorderedEquals(['Als Ort speichern', 'Ort teilen']));
    handle.dispose();
  });

  testWidgets('while a place is swiped open the list stays, then it shows the new direction',
      (tester) async {
    await pumpScreen(tester);
    await point(tester, 0);
    expect(find.text('Café Einstein'), findsOneWidget);

    await tester.drag(find.text('Café Einstein'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.share), findsOneWidget);

    await point(tester, 180); // south: no places there
    expect(find.text('Café Einstein'), findsOneWidget);

    // the row slides back, as after a tap beside the menu
    unawaited(Slidable.of(tester.element(find.text('Café Einstein')))!.close());
    await tester.pumpAndSettle();
    expect(find.text('Café Einstein'), findsNothing);
  });

  testWidgets('with a screen reader a new direction moves the focus to the header of the list',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    announcements.clear();
    focusedNodes.clear();

    await point(tester, 0);
    await tester.pump();

    // the header says the direction and the number of places; reading it out is the announcement
    final header = tester.getSemantics(find.bySemanticsLabel('Norden, 2 nahegelegene Orte.'));
    expect(focusedNodes, [header.id]);
    expect(announcements, isEmpty);

    // the focus is on the header already: focusing it again would say nothing
    tester.binding.renderViews.first.owner!.semanticsOwner!
        .performAction(header.id, SemanticsAction.didGainAccessibilityFocus);
    await point(tester, 90); // east: no places, so no header
    expect(announcements.last, startsWith('Osten'));
    await point(tester, 0);
    await tester.pump();
    expect(announcements.last, 'Norden, 2 nahegelegene Orte.');
    expect(focusedNodes, [header.id]);
    handle.dispose();
  });

  testWidgets('shows a hint when the phone is tilted', (tester) async {
    await pumpScreen(tester);

    compass.horizontalController.add(false);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.textContaining('horizontal halten'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // snackbar timer
  });

  testWidgets('the heading bar tells sighted users to point the phone, then shows the direction',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('In eine Richtung zeigen'), findsOneWidget);

    await point(tester, 0);
    expect(find.text('NORDEN'), findsOneWidget);
    expect(find.text('2 Orte'), findsOneWidget);

    await point(tester, 25); // between north and north-east: the list still shows north
    expect(find.text('NORDEN'), findsOneWidget);
  });

  testWidgets('the heading bar is not read out twice by screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);
    await point(tester, 0);
    expect(find.bySemanticsLabel('NORDEN'), findsNothing);
    semantics.dispose();
  });

  testWidgets('shows an error with a retry button instead of crashing', (tester) async {
    repository.result = Result.error(Exception('overpass down'));
    await pumpScreen(tester);

    expect(find.textContaining('konnten gerade nicht geladen werden'), findsOneWidget);

    repository.result = const Result.ok([cafe]);
    await tester.tap(find.text('Erneut versuchen'));
    await point(tester, 0);
    expect(find.text('Café Einstein'), findsOneWidget);
  });

  group('meets accessibility guidelines', () {
    for (final (name, setup) in [
      ('list', () {}),
      ('error', () => repository.result = Result.error(Exception('down'))),
      ('empty', () => repository.result = const Result.ok([])),
    ]) {
      testWidgets(name, (tester) async {
        final handle = tester.ensureSemantics();
        setup();
        await pumpScreen(tester);
        await point(tester, 0);

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
