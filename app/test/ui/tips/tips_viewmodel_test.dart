import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/repositories/tips/tips_repository.dart';
import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/ui/tips/view_models/tips_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../fakes/fake_tips_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TipsRepository repository;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    repository = TipsRepository(
      tipsService: FakeTipsService(),
      settingsRepository: settings,
      languageService: LanguageService(preferredLocales: () => const [Locale('en')]),
    );
  });

  test('unread tips come first; an opened tip moves down as read', () async {
    final viewModel = TipsViewModel(tipsRepository: repository);
    await pumpEventQueue();
    expect(viewModel.tips.map((tip) => tip.id), ['notes', 'radar']);

    await viewModel.open(viewModel.tips.first);
    await pumpEventQueue();
    expect(viewModel.tips.map((tip) => tip.id), ['radar', 'notes']);
    expect(viewModel.tips.last.read, isTrue);
    viewModel.dispose();
  });

  test('a broken tips file shows an error', () async {
    final viewModel = TipsViewModel(
      tipsRepository: TipsRepository(
        tipsService: FakeTipsService(null),
        settingsRepository: SettingsRepository(await SharedPreferencesWithCache.create(
            cacheOptions: const SharedPreferencesWithCacheOptions())),
        languageService: LanguageService(preferredLocales: () => const [Locale('en')]),
      ),
    );
    await pumpEventQueue();
    expect(viewModel.load.error, isTrue);
    viewModel.dispose();
  });
}
