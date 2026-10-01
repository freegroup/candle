import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:vibration/vibration.dart';

final _log = Logger();

/// Haptic feedback that the user can turn off in the settings. Devices
/// without a vibration motor (iPads) play a click sound instead.
class VibrationService {
  VibrationService({required SettingsRepository settingsRepository})
      : _settings = settingsRepository;

  final SettingsRepository _settings;
  final _player = AudioPlayer();
  bool? _hasVibrator;

  /// Feedback while navigating along a route.
  Future<void> navigation({int duration = 500, int repeat = -1}) =>
      _vibrate(Setting.vibrateDuringNavigation, duration, repeat);

  /// Feedback of the compass screens when a direction is reached.
  Future<void> compass({int duration = 500, int repeat = -1}) =>
      _vibrate(Setting.vibrateCompass, duration, repeat);

  Future<void> _vibrate(Setting setting, int duration, int repeat) async {
    if (!_settings.isEnabled(setting)) return;
    try {
      if (await _canVibrate()) {
        await Vibration.vibrate(duration: duration, repeat: repeat);
      } else {
        await _player.play(AssetSource('sounds/click.mp3'));
      }
    } on Exception catch (e) {
      _log.w('Feedback failed: $e');
    }
  }

  Future<bool> _canVibrate() async {
    if (_hasVibrator case final cached?) return cached;
    if (Platform.isIOS && (await DeviceInfoPlugin().iosInfo).model.toLowerCase().contains('ipad')) {
      return _hasVibrator = false;
    }
    return _hasVibrator = await Vibration.hasVibrator();
  }
}
