import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/ui/settings/view_models/settings_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SettingsRepository settings;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
  });

  test('uses the defaults until the user changes a setting', () async {
    final viewModel = SettingsViewModel(settingsRepository: settings);
    expect(viewModel.isEnabled(Setting.vibrateCompass), isTrue);
    expect(viewModel.isEnabled(Setting.betaRecording), isFalse);

    var notified = 0;
    viewModel.addListener(() => notified++);
    await viewModel.setEnabled(Setting.vibrateCompass, false);
    expect(viewModel.isEnabled(Setting.vibrateCompass), isFalse);
    expect(notified, 1);
  });

  test('offers the recording tile only while recording is enabled', () async {
    final viewModel = SettingsViewModel(settingsRepository: settings);
    expect(viewModel.tiles, isNot(contains(Setting.overviewRecorder)));

    await viewModel.setEnabled(Setting.betaRecording, true);
    expect(viewModel.tiles, contains(Setting.overviewRecorder));
  });
}
