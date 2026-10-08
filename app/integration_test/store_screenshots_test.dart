// Walks through the real app for the App Store screenshots: store/screenshots.sh
// runs it on a simulator and takes a screenshot at every "SCREENSHOT <name>" line.
//
// Real services and network; only what a test on a simulator lacks is replaced:
// the permissions (granted), the position (Pariser Platz in Berlin, a public
// place) and the compass (a fixed heading).
import 'dart:async';

import 'package:candle/app.dart';
import 'package:candle/config/dependencies.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/ui/core/widgets/list_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class _Granted extends PermissionService {
  @override
  Future<bool> allGranted() async => true;

  @override
  Future<bool> requestAll() async => true;
}

const _pariserPlatz = LatLng(52.5163, 13.3777);

class _FixedPosition implements LocationService {
  @override
  Future<Result<LatLng>> currentPosition() async => const Result.ok(_pariserPlatz);

  @override
  Future<Result<double>> currentAccuracy({required Duration timeLimit}) async => const Result.ok(5);

  @override
  Stream<LatLng> positions() => Stream.periodic(const Duration(seconds: 1), (_) => _pariserPlatz);

  @override
  Stream<LatLng> backgroundPositions({required String title, required String text}) => positions();
}

class _FixedCompass extends CompassService {
  @override
  Stream<double> headings() => Stream.periodic(const Duration(milliseconds: 500), (_) => 90.0);

  @override
  Stream<bool> isHorizontal() => Stream.value(true);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Waits for the screen to settle (network, animations), then has the host take a screenshot.
  Future<void> screenshot(WidgetTester tester, String name, {int seconds = 4}) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // ignore: avoid_print
    print('SCREENSHOT $name');
    // the host needs a moment to take it
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    // on a large screen a tile can be below the visible part
    await tester.ensureVisible(find.text(text).last);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text(text).last);
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('store screenshots', (tester) async {
    final settings = await SettingsRepository.load();
    await settings.setWelcomeSeen((await PackageInfo.fromPlatform()).version);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ...providers,
        Provider<PermissionService>(create: (_) => _Granted()),
        Provider<CompassService>(create: (_) => _FixedCompass()),
        Provider<LocationService>(create: (_) => _FixedPosition()),
      ],
      child: const CandleApp(),
    ));

    await screenshot(tester, '01_uebersicht', seconds: 8);

    await tapText(tester, 'Erkunden');
    await screenshot(tester, '02_erkunden');

    await tapText(tester, 'Cafés');
    await screenshot(tester, '03_cafes', seconds: 15);

    await tester.tap(find.byType(CandleListTile).first);
    await tester.pump(const Duration(milliseconds: 600));
    await screenshot(tester, '04_kompass_ziel', seconds: 5);

    // back to the categories, then to the tabs
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(BackButton).last);
      await tester.pump(const Duration(seconds: 1));
    }

    await tapText(tester, 'Orte Radar');
    await screenshot(tester, '05_radar', seconds: 15);
  });
}
