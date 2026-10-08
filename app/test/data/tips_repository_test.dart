import 'dart:convert';
import 'dart:io';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/repositories/tips/tips_repository.dart';
import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/domain/models/tip.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_tips_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsRepository settings;
  late FakeTipsService service;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    service = FakeTipsService();
  });

  TipsRepository create(String language) => TipsRepository(
        tipsService: service,
        settingsRepository: settings,
        languageService: LanguageService(preferredLocales: () => [Locale(language)]),
      );

  List<Tip> tipsOf(Result<List<Tip>> result) => (result as Ok<List<Tip>>).value;

  test('tips in the language of the app, English when a text is missing', () async {
    final tips = tipsOf(await create('de').tips());
    expect(tips.map((tip) => tip.title), ['Was sind Ortsnotizen?', 'The radar']);
    expect(tips.first.paragraphs, ['Ein Hinweis.', 'Kommst du vorbei, vibriert es.']);
  });

  test('a tip is unread until it is opened, and stays read', () async {
    final repository = create('en');
    expect(tipsOf(await repository.tips()).map((tip) => tip.read), [false, false]);

    var notified = 0;
    repository.addListener(() => notified++);
    await repository.markRead('radar');
    expect(notified, 1);
    expect(tipsOf(await repository.tips()).map((tip) => tip.read), [false, true]);

    // also for the next start of the app
    expect(tipsOf(await create('en').tips()).map((tip) => tip.read), [false, true]);
  });

  test('a missing or broken tips file is an error, no crash', () async {
    service.json = null;
    expect(await create('de').tips(), isA<Error<List<Tip>>>());
    service.json = '{"tips": [{"id": 1}]}';
    expect(await create('de').tips(), isA<Error<List<Tip>>>());
  });

  test('every tip that comes with the app has an id of its own and texts in all app languages', () {
    final file = jsonDecode(File('assets/tips/tips.json').readAsStringSync()) as Map<String, dynamic>;
    final tips = (file['tips'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(tips, isNotEmpty);
    expect(tips.map((tip) => tip['id']).toSet(), hasLength(tips.length));
    for (final tip in tips) {
      for (final language in ['de', 'en']) {
        expect((tip['title'] as Map)[language], isNotEmpty, reason: '${tip['id']} title $language');
        expect((tip['text'] as Map)[language], isNotEmpty, reason: '${tip['id']} text $language');
      }
    }
  });
}
