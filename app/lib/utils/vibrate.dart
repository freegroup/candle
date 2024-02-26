import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vibration/vibration.dart';

class CandleVibrate {
  static final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isCached = false;

  static void vibrateDuringNavigation({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
  }) async {
    if (AppFeatures.vibrateDuringNavigation.isEnabled) {
      if (await _hasVibrator()) {
        Vibration.vibrate(
            duration: duration,
            repeat: repeat,
            pattern: pattern,
            intensities: intensities,
            amplitude: amplitude);
      } else {
        _playClickSound();
      }
    }
  }

  static Future<void> vibrateCompass({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
  }) async {
    print("vibrateCompass");
    if (AppFeatures.vibrateCompass.isEnabled) {
      if (await _hasVibrator()) {
        Vibration.vibrate(
            duration: duration,
            repeat: repeat,
            pattern: pattern,
            intensities: intensities,
            amplitude: amplitude);
      } else {
        await _playClickSound();
      }
    }
  }

  static Future<void> _playClickSound() async {
    try {
      print("click");
      // Ensure the audio file is cached before playing.
      if (!_isCached) {
        await _audioCache.load('click.mp3');
        _isCached = true;
      }

      // Play the cached audio file.
      final source = AssetSource("sounds/click.mp3");
      //final source = BytesSource(await _audioCache.loadAsBytes("click.mp3"));

      await _audioPlayer.play(source);
    } catch (e) {
      print("Exception for playClickSound");
    }
  }

  static Future<bool> _hasVibrator() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    // Check the platform before accessing platform-specific APIs
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      if (iosInfo.model.toLowerCase().contains("ipad")) {
        return false;
      }
    }

    // For Android, or if it's an iPhone (which wasn't caught by the if block)
    return await Vibration.hasVibrator() ?? false;
  }
}
