import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';

/// The switches of the settings screen.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository settingsRepository})
      : _settings = settingsRepository {
    _settings.addListener(notifyListeners);
  }

  final SettingsRepository _settings;

  /// Home screen tiles; the recording tile only while recording is enabled.
  List<Setting> get tiles => [
        Setting.overviewCompass,
        Setting.overviewLocation,
        Setting.overviewRadar,
        Setting.overviewWikipedia,
        if (isEnabled(Setting.betaRecording)) Setting.overviewRecorder,
        Setting.overviewShare,
      ];

  List<Setting> get common => [
        if (Setting.dictationInput.isAvailable) Setting.dictationInput,
        Setting.vibrateCompass,
        Setting.vibrateDuringNavigation,
      ];

  List<Setting> get beta => const [Setting.betaRecording];

  bool isEnabled(Setting setting) => _settings.isEnabled(setting);

  Future<void> setEnabled(Setting setting, bool value) => _settings.setEnabled(setting, value);

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
