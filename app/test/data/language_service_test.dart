import 'dart:ui';

import 'package:candle/data/services/language/language_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Locale> system;
  LanguageService create() => LanguageService(preferredLocales: () => system);

  test('uses the first system language the app has texts for', () {
    system = const [Locale('fr'), Locale('de', 'AT')];
    expect(create().languageCode, 'de');
  });

  test('decides like the app texts do: an exact match beats a language-only match', () {
    system = const [Locale('fr'), Locale('de', 'AT'), Locale('en')];
    expect(create().languageCode, 'en');
  });

  test('falls back like the app texts when no system language is supported', () {
    system = const [Locale('fr')];
    final service = create();
    expect(['de', 'en'], contains(service.languageCode));
  });

  test('follows a change of the language in the device settings', () {
    system = const [Locale('de')];
    final service = create();
    var notified = 0;
    service.addListener(() => notified++);

    system = const [Locale('en', 'GB')];
    service.didChangeLocales(system);
    expect(service.languageCode, 'en');
    expect(notified, 1);

    service.didChangeLocales(system);
    expect(notified, 1, reason: 'no change, no notification');
    service.dispose();
  });
}
