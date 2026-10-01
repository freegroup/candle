import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/explore/view_models/poi_category_viewmodel.dart';
import 'package:candle/ui/explore/widgets/poi_category_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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
const crossing = Poi(id: 2, kind: PoiKind.crossingZebra, position: LatLng(52.5180, 13.3777));

void main() {
  late FakePoiRepository repository;

  Future<void> pumpScreen(WidgetTester tester, {bool screenReader = false}) async {
    final viewModel = PoiCategoryViewModel(
      category: PoiCategory.cafes,
      poiRepository: repository,
      locationService: FakeLocationService(const Result.ok(here)),
      geocodingRepository: FakeGeocodingRepository(),
    );
    await tester.pumpWidget(MaterialApp(
      theme: CThemeData.darkTheme,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(accessibleNavigation: screenReader),
        child: PoiCategoryScreen(viewModel: viewModel),
      ),
    ));
    await tester.pump();
    // let the delayed screen/result announcements run out
    await tester.pump(const Duration(seconds: 4));
  }

  setUp(() => repository = FakePoiRepository(const Result.ok([cafe, crossing])));

  testWidgets('lists places with localized names, address and distance', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Café Einstein'), findsOneWidget);
    expect(find.text('Unter den Linden 42, Berlin'), findsOneWidget);
    expect(find.text('78 m'), findsOneWidget);
    expect(find.text('Zebrastreifen'), findsOneWidget);
    expect(find.text('Liste'), findsOneWidget); // tabs without screen reader
  });

  testWidgets('offers edit and share as screen reader actions', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);

    final node = tester.getSemantics(find.text('Café Einstein'));
    final actions = <String>[];
    SemanticsNode? current = node;
    while (current != null && actions.isEmpty) {
      final ids = current.getSemanticsData().customSemanticsActionIds ?? [];
      actions.addAll(ids.map((id) => CustomSemanticsAction.getAction(id)!.label!));
      current = current.parent;
    }
    expect(actions, hasLength(2));
    handle.dispose();
  });

  testWidgets('with a screen reader the map tab is left out', (tester) async {
    await pumpScreen(tester, screenReader: true);

    expect(find.text('Café Einstein'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('shows an error with a retry button instead of crashing', (tester) async {
    repository.result = Result.error(Exception('overpass down'));
    await pumpScreen(tester);

    expect(find.textContaining('konnten gerade nicht geladen werden'), findsOneWidget);
    expect(find.bySemanticsLabel('Die Orte erneut laden'), findsOneWidget);

    repository.result = const Result.ok([cafe]);
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
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

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
