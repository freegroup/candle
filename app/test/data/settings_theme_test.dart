import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/ui/core/themes/candle_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepository settings;
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
  });

  test('the default theme is the first profile', () {
    expect(settings.themeId, 'amber_dark');
    expect(settings.colorTheme.id, 'amber_dark');
  });

  test('selecting a theme persists it and notifies listeners', () async {
    var notified = 0;
    settings.addListener(() => notified++);
    await settings.setThemeId('black_light');
    expect(settings.themeId, 'black_light');
    expect(settings.colorTheme.id, 'black_light');
    expect(notified, 1);
  });

  test('an unknown stored id falls back to the default', () async {
    await settings.setThemeId('does_not_exist');
    expect(settings.colorTheme.id, candleThemes.first.id);
  });
}
