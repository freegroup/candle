import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A switch the user can turn on or off in the settings.
///
/// The keys are the ones of the former `AppFeatures`.
enum Setting {
  overviewCompass('overviewCompass'),
  overviewLocation('overviewLocation'),
  overviewRecorder('overviewRecorder'),
  overviewRadar('overviewRadar'),
  overviewShare('overviewShare'),
  overviewWikipedia('overviewWikipedia'),
  // Vibration can be annoying for sighted users, so it can be turned off.
  vibrateDuringNavigation('vibrateDuringNavigation'),
  vibrateCompass('vibrateCompass'),
  // Route recording is still beta and off by default.
  betaRecording('betaRecording', initial: false),
  // Short screen reader texts for experienced users (see lib/l10n/arb/short).
  shortTalkback('shortTalkback', initial: false),
  // iOS has its own dictation key on the keyboard.
  dictationInput('dictationInput', supportedOnIOS: false);

  const Setting(this.key, {this.initial = true, this.supportedOnIOS = true});

  final String key;
  final bool initial;
  final bool supportedOnIOS;

  /// Whether the setting exists on this platform at all.
  bool get isAvailable => supportedOnIOS || !Platform.isIOS;
}

/// The user's settings; notifies listeners on every change.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SettingsRepository> load() async => SettingsRepository(
      await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions()));

  bool isEnabled(Setting setting) =>
      setting.isAvailable && (_prefs.getBool(setting.key) ?? setting.initial);

  Future<void> setEnabled(Setting setting, bool value) async {
    await _prefs.setBool(setting.key, value);
    notifyListeners();
  }
}
