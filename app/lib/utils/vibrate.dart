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
        playClickSound();
      }
    }
  }

  static void vibrateCompass({
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
        playClickSound();
      }
    }
  }

  static Future<void> preloadAudio() async {
    await _audioCache.load('click.mp3');
    _isCached = true; // Mark as cached
  }

  static Future<void> playClickSound() async {
    // Ensure the audio file is cached before playing.
    if (!_isCached) await preloadAudio();

    // Play the cached audio file.
    final source = AssetSource("sounds/click.mp3");
    await _audioPlayer.play(source);
  }

  static Future<bool> _hasVibrator() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo info = await deviceInfo.iosInfo;
    if (info.model.toLowerCase().contains("ipad")) {
      return false;
    }
    return await Vibration.hasVibrator() ?? false;
  }
}
