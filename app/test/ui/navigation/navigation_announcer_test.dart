import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/accessibility/accessibility_service.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/navigation/announcers/navigation_announcer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeAccessibility extends AccessibilityService {
  int interrupts = 0;

  @override
  Future<void> interrupt() async => interrupts++;
}

// Not extending the real one: that creates an audio player, which tests do not have.
class _FakeVibration implements VibrationService {
  /// The durations, with the repeat for repeated ones, e.g. '100' or '100x2'.
  final vibrations = <String>[];

  @override
  Future<void> navigation({int duration = 500, int repeat = -1}) async =>
      vibrations.add(repeat < 0 ? '$duration' : '${duration}x$repeat');

  @override
  Future<void> navigationPulses(int count) async {}

  @override
  Future<void> compass({int duration = 500, int repeat = -1}) async {}
}

// 50 m to the next waypoint, the route turns left there, the phone points to it.
NavigationGuidance _guidance(NavigationEvent event) => NavigationGuidance(
      event: event,
      hasWaypoint: true,
      distanceToWaypoint: 50,
      turnAngle: 90,
      isAligned: true,
    );

void main() {
  late SettingsRepository settings;
  late _FakeAccessibility accessibility;
  late _FakeVibration vibration;
  late StreamController<NavigationGuidance> guidance;
  late List<String> announced;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    accessibility = _FakeAccessibility();
    vibration = _FakeVibration();
    guidance = StreamController();
    announced = [];
  });
  // not awaited: without a listener the close never completes
  tearDown(() => unawaited(guidance.close()));

  Future<void> follow(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final map = message! as Map<Object?, Object?>;
        if (map['type'] == 'announce') {
          announced.add((map['data']! as Map<Object?, Object?>)['message']! as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));

    final announcer = NavigationAnnouncer(
      settingsRepository: settings,
      vibrationService: vibration,
      accessibilityService: accessibility,
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        announcer.follow(context, guidance.stream);
        return const SizedBox();
      }),
    ));
  }

  Future<void> send(WidgetTester tester, NavigationEvent event) async {
    guidance.add(_guidance(event));
    await tester.pump();
  }

  testWidgets('announces in full sentences by default', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.routeCalculated);
    expect(announced, ['Sie zeigen direkt auf den nächsten Wegpunkt. Nach 50 Metern, links abbiegen.']);
    // the new route follows what is said right now
    expect(accessibility.interrupts, 0);
    expect(vibration.vibrations, ['100']);
  });

  testWidgets('the short style says meters and direction only', (tester) async {
    await settings.setNavigationStyleId('short');
    await follow(tester);

    await send(tester, NavigationEvent.waypointPassed);
    expect(announced, ['50 Meter, links']);
    // the directions to the passed waypoint are outdated
    expect(accessibility.interrupts, 1);

    await send(tester, NavigationEvent.offRoute);
    expect(announced.last, 'Neue Route');
    await send(tester, NavigationEvent.targetReached);
    expect(announced.last, 'Ziel erreicht');
    expect(accessibility.interrupts, 3);
  });

  testWidgets('pointing to the waypoint vibrates without speaking', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.aligned);
    await send(tester, NavigationEvent.notAligned);
    await send(tester, NavigationEvent.update);
    expect(vibration.vibrations, ['100x2', '500']);
    expect(announced, isEmpty);
  });

  testWidgets('leaving the route is said instead of the outdated directions', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.offRoute);
    expect(accessibility.interrupts, 1);
    expect(announced, ['Sie haben die Route verlassen. Eine neue Route wird berechnet.']);
  });

  testWidgets('the end of the navigation stops speaking', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.stopped);
    expect(accessibility.interrupts, 1);
    expect(announced, isEmpty);
  });

  testWidgets('an unknown style id falls back to the default', (tester) async {
    await settings.setNavigationStyleId('gone');
    expect(navigationStyleFor(settings.navigationStyleId).id, 'detailed');
  });
}
