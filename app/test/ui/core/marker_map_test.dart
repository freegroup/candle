import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/core/widgets/marker_map.dart';
import 'package:candle/ui/core/widgets/marker_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_compass_service.dart';

const _pariserPlatz = LatLng(52.5163, 13.3777);
const _someStepsOn = LatLng(52.5166, 13.3780);

// A place a little north-east of the user, so its marker is not under the user's own.
final _cafe = LocationAddress(
  name: 'Café Einstein',
  formattedAddress: 'Unter den Linden 42, Berlin',
  street: 'Unter den Linden',
  number: '42',
  zip: '10117',
  city: 'Berlin',
  country: 'Deutschland',
  lat: 52.5166,
  lon: 13.3781,
);

void main() {
  Future<void> pumpMap(WidgetTester tester, LatLng position) async {
    await tester.pumpWidget(Provider<CompassService>.value(
      value: FakeCompassService(),
      child: MaterialApp(
        theme: CThemeData.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MarkerMapWidget(
            currentLocation: position,
            pinImage: 'assets/images/location_marker.png',
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  // The middle of the map, rounded to about a meter.
  LatLng mapCenter(WidgetTester tester) {
    final center = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!.camera.center;
    return LatLng(
      double.parse(center.latitude.toStringAsFixed(5)),
      double.parse(center.longitude.toStringAsFixed(5)),
    );
  }

  LatLng rounded(LatLng position) => LatLng(
        double.parse(position.latitude.toStringAsFixed(5)),
        double.parse(position.longitude.toStringAsFixed(5)),
      );

  Finder myPositionMarker() => find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage && image.assetName == 'assets/images/my_location_marker.png';
      });

  // The map with one place whose marker can be tapped.
  Future<void> pumpMapWithCafe(WidgetTester tester, List<LocationAddress> navigated) async {
    await tester.pumpWidget(Provider<CompassService>.value(
      value: FakeCompassService(),
      child: MaterialApp(
        theme: CThemeData.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MarkerMapWidget(
            currentLocation: _pariserPlatz,
            pins: [_cafe],
            pinImage: 'assets/images/location_marker.png',
            pinInfo: (place) => PinInfo(title: place.name, subtitle: place.formattedAddress),
            onNavigate: navigated.add,
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  Finder placeMarker() => find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage && image.assetName == 'assets/images/location_marker.png';
      });

  // Lets the tile requests and the pulse of the marker end with the test.
  Future<void> removeMap(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('shows the own position and follows it', (tester) async {
    await pumpMap(tester, _pariserPlatz);

    expect(myPositionMarker(), findsOneWidget);
    expect(find.text('Zentrieren'), findsNothing);
    expect(mapCenter(tester), rounded(_pariserPlatz));

    await pumpMap(tester, _someStepsOn);
    expect(mapCenter(tester), rounded(_someStepsOn));
    expect(find.text('Zentrieren'), findsNothing);

    await removeMap(tester);
  });

  testWidgets('a moved map stays where it is and offers to center again', (tester) async {
    await pumpMap(tester, _pariserPlatz);

    await tester.drag(find.byType(FlutterMap), const Offset(150, 80));
    await tester.pump();
    expect(find.text('Zentrieren'), findsOneWidget);
    final moved = mapCenter(tester);
    expect(moved, isNot(rounded(_pariserPlatz)));

    // a new position does not pull the map back
    await pumpMap(tester, _someStepsOn);
    expect(mapCenter(tester), moved);

    await tester.tap(find.text('Zentrieren'));
    await tester.pump();
    expect(mapCenter(tester), rounded(_someStepsOn));
    expect(find.text('Zentrieren'), findsNothing);

    await removeMap(tester);
  });

  testWidgets('a tapped place shows its address at the top, a tap on it starts the navigation',
      (tester) async {
    final navigated = <LocationAddress>[];
    await pumpMapWithCafe(tester, navigated);
    expect(find.text('Café Einstein'), findsNothing);

    await tester.tap(placeMarker());
    await tester.pump();
    expect(find.text('Café Einstein'), findsOneWidget);
    expect(find.text('Unter den Linden 42, Berlin'), findsOneWidget);
    expect(find.text('Navigation starten'), findsOneWidget);
    // at the top: the button to center the map has the bottom for itself
    final mapHeight = tester.getSize(find.byType(FlutterMap)).height;
    expect(tester.getCenter(find.text('Café Einstein')).dy, lessThan(mapHeight / 2));
    expect(navigated, isEmpty);

    await tester.tap(find.text('Unter den Linden 42, Berlin'));
    await tester.pump();
    expect(navigated, [_cafe]);

    await removeMap(tester);
  });

  testWidgets('a tap beside the places closes the address again', (tester) async {
    await pumpMapWithCafe(tester, []);
    await tester.tap(placeMarker());
    await tester.pump();
    expect(find.text('Café Einstein'), findsOneWidget);

    final map = tester.getRect(find.byType(FlutterMap));
    await tester.tapAt(map.bottomLeft + const Offset(40, -40));
    // the map waits whether a second tap follows before it reports the tap
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Café Einstein'), findsNothing);

    await removeMap(tester);
  });

  testWidgets('without a description the places cannot be tapped', (tester) async {
    await tester.pumpWidget(Provider<CompassService>.value(
      value: FakeCompassService(),
      child: MaterialApp(
        theme: CThemeData.darkTheme,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MarkerMapWidget(
            currentLocation: _pariserPlatz,
            pins: [_cafe],
            pinImage: 'assets/images/location_marker.png',
          ),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(placeMarker());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Navigation starten'), findsNothing);

    await removeMap(tester);
  });

  testWidgets('without animations the marker does not pulse', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpMap(tester, _pariserPlatz);

    expect(myPositionMarker(), findsOneWidget);
    // nothing is animating, so the screen comes to rest
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5));

    await removeMap(tester);
  });
}
