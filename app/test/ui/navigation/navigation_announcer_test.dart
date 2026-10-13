import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/navigation/announcers/announcer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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
  late int interrupts;
  // The durations, with the repeat for repeated ones, e.g. '100' or '100x2'.
  late List<String> vibrations;
  late StreamController<NavigationGuidance> guidance;
  late List<String> announced;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    interrupts = 0;
    vibrations = [];
    VibrationService.recorder = (duration, repeat, pattern) =>
        vibrations.add(repeat < 0 ? '$duration' : '${duration}x$repeat');
    guidance = StreamController();
    announced = [];
  });
  // not awaited: without a listener the close never completes
  tearDown(() => unawaited(guidance.close()));
  tearDown(() => VibrationService.recorder = null);

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
    // TTS.interrupt stops the screen reader over this channel
    const interruptChannel = MethodChannel('candle/accessibility');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(interruptChannel, (call) async {
      if (call.method == 'interrupt') interrupts++;
      return null;
    });
    addTearDown(() =>
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(interruptChannel, null));

    final announcer = NavigationAnnouncer(
      settingsRepository: settings,
    );
    // the styles read the vibration setting from the providers
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          announcer.follow(context, guidance.stream);
          return const SizedBox();
        }),
      ),
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
    expect(interrupts, 0);
    expect(vibrations, ['100']);
  });

  testWidgets('the short style says meters and direction only', (tester) async {
    await settings.setNavigationStyleId('short');
    await follow(tester);

    await send(tester, NavigationEvent.waypointPassed);
    expect(announced, ['50 Meter, links']);
    // the directions to the passed waypoint are outdated
    expect(interrupts, 1);

    await send(tester, NavigationEvent.offRoute);
    expect(announced.last, 'Neue Route');
    await send(tester, NavigationEvent.targetReached);
    expect(announced.last, 'Ziel erreicht');
    expect(interrupts, 3);
  });

  testWidgets('a style chosen during the navigation counts at once', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.waypointPassed);
    expect(announced.last, 'Sie zeigen direkt auf den nächsten Wegpunkt. Nach 50 Metern, links abbiegen.');

    await settings.setNavigationStyleId('short');
    await send(tester, NavigationEvent.waypointPassed);
    expect(announced.last, '50 Meter, links');
  });

  testWidgets('pointing to the waypoint vibrates without speaking', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.aligned);
    await send(tester, NavigationEvent.notAligned);
    await send(tester, NavigationEvent.update);
    expect(vibrations, ['100x2', '500']);
    expect(announced, isEmpty);
  });

  testWidgets('leaving the route is said instead of the outdated directions', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.offRoute);
    expect(interrupts, 1);
    expect(announced, ['Sie haben die Route verlassen. Eine neue Route wird berechnet.']);
  });

  testWidgets('the end of the navigation stops speaking', (tester) async {
    await follow(tester);

    await send(tester, NavigationEvent.stopped);
    expect(interrupts, 1);
    expect(announced, isEmpty);
  });

  testWidgets('an unknown style id falls back to the default', (tester) async {
    await settings.setNavigationStyleId('gone');
    expect(NavigationAnnouncer.styleById(settings.navigationStyleId).id, 'detailed');
  });
}
