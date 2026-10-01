import 'package:candle/config/dependencies.dart';
import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/data/repositories/recording/recording_repository.dart';
import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/repositories/voicepins/voicepin_repository.dart';
import 'package:candle/data/repositories/wikipedia/wikipedia_repository.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  // provider checks the provider types only in debug builds, so a wrong one
  // (e.g. Provider for a ChangeNotifier) shows up here and not in release.
  testWidgets('every repository can be read from the app providers', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    late BuildContext context;
    await tester.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider.value(value: settings), ...providers],
      child: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));

    expect(context.read<RecordingRepository>(), isNotNull);
    expect(context.read<LocationRepository>(), isNotNull);
    expect(context.read<VoicePinRepository>(), isNotNull);
    expect(context.read<RouteRepository>(), isNotNull);
    expect(context.read<RoutingRepository>(), isNotNull);
    expect(context.read<WikipediaRepository>(), isNotNull);
    expect(context.read<VibrationService>(), isNotNull);

    // let the server registration started with the app give up (no network in tests)
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
