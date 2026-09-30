import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/ui/radar/view_models/radar_viewmodel.dart';
import 'package:candle/ui/radar/widgets/radar_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_compass_service.dart';
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
  late int vibrations;

  Future<void> pumpScreen(WidgetTester tester) async {
    viewModel = RadarViewModel(
      poiRepository: repository,
      locationService: FakeLocationService(const Result.ok(here)),
      compassService: compass,
    );
    await tester.pumpWidget(MaterialApp(
      theme: CThemeData.darkTheme,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RadarScreen(viewModel: viewModel, vibrate: () async => vibrations++),
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

  setUp(() {
    repository = FakePoiRepository(const Result.ok([cafe, signal]));
    compass = FakeCompassService();
    announcements = [];
    vibrations = 0;
  });

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (Object? message) async {
        final data = (message! as Map<Object?, Object?>)['data']! as Map<Object?, Object?>;
        if (data['message'] case final String text) announcements.add(text);
        return null;
      },
    );
  });

  tearDown(() => viewModel.dispose());

  testWidgets('lists the places of the direction and announces it', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Café Einstein'), findsNothing);

    await point(tester, 3);

    expect(find.text('Café Einstein'), findsOneWidget);
    expect(find.text('Unter den Linden 42, Berlin'), findsOneWidget);
    expect(find.text('78 m'), findsOneWidget);
    expect(vibrations, 1);
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

  testWidgets('shows a hint when the phone is tilted', (tester) async {
    await pumpScreen(tester);

    compass.horizontalController.add(false);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.textContaining('horizontal halten'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // snackbar timer
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
