import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:candle/config/app_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vibration/vibration.dart';

final _log = Logger();

/// Makes the phone vibrate. Devices without a vibration motor (iPads) play a
/// click sound instead.
///
/// Only a tool: whether to vibrate at all, for example because the user turned
/// vibration off in the settings, is decided by the caller.
abstract final class VibrationService {
  /// Tests set this to record the pulses instead of running the motor; they have
  /// neither a vibration motor nor an audio player.
  @visibleForTesting
  static void Function(int duration, int repeat, List<int> pattern)? recorder;

  static AudioPlayer? _player;
  static bool? _hasVibrator;

  /// Vibrates for [duration] milliseconds, or in the rhythm of [pattern] (pause,
  /// vibration, pause, ... in milliseconds). [repeat] is passed on to the motor.
  static Future<void> pulse({int duration = 500, int repeat = -1, List<int> pattern = const []}) async {
    final record = recorder;
    if (record != null) {
      record(duration, repeat, pattern);
      return;
    }
    try {
      if (await _canVibrate()) {
        await Vibration.vibrate(duration: duration, repeat: repeat, pattern: pattern);
      } else {
        _player ??= AudioPlayer();
        await _player!.play(AssetSource('sounds/click.mp3'));
      }
    } on Exception catch (e) {
      _log.w('Feedback failed: $e');
    }
  }

  /// [count] short pulses in a row, for example at a location note.
  static Future<void> pulses(int count) => pulse(duration: 0, pattern: [
        for (var i = 0; i < count; i++) ...[
          i == 0 ? 0 : VibrationConfig.pulsePause,
          VibrationConfig.pulseLength,
        ],
      ]);

  static Future<bool> _canVibrate() async {
    final cached = _hasVibrator;
    if (cached != null) return cached;
    if (Platform.isIOS && (await DeviceInfoPlugin().iosInfo).model.toLowerCase().contains('ipad')) {
      return _hasVibrator = false;
    }
    return _hasVibrator = await Vibration.hasVibrator();
  }
}
