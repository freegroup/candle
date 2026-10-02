import 'dart:io';

import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/l10n/localizations_delegate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_short_l10n.dart' as generator;

void main() {
  test('the generated short texts are up to date (run: dart run tool/gen_short_l10n.dart)', () {
    for (final MapEntry(key: path, value: content) in generator.generate().entries) {
      expect(File(path).readAsStringSync(), content, reason: path);
    }
  });

  Future<AppLocalizations> load(String language, {required bool short}) =>
      CandleLocalizationsDelegate(short: short).load(Locale(language));

  test('short texts keep the information and drop the explanation', () async {
    final long = await load('de', short: false);
    final short = await load('de', short: true);

    expect(long.label_rotate_left_target_t(45), '45 Grad nach links, um direkt auf das Ziel zu zeigen.');
    expect(short.label_rotate_left_target_t(45), '45 Grad links');
    expect(short.location_distance_t('Bäcker', 120), 'Bäcker, 120 Meter');
    expect((await load('en', short: true)).label_rotate_no_target_t(80), 'Target ahead, 80 meters');
  });

  test('texts without a short version stay the same', () async {
    final long = await load('de', short: false);
    final short = await load('de', short: true);
    expect(short.button_common_save, long.button_common_save);
    expect(short.recording_cancel_body, long.recording_cancel_body);
  });

  test('switching the setting reloads the texts', () {
    const long = CandleLocalizationsDelegate(short: false);
    const short = CandleLocalizationsDelegate(short: true);
    expect(short.shouldReload(long), isTrue);
    expect(long.shouldReload(const CandleLocalizationsDelegate(short: false)), isFalse);
  });
}
