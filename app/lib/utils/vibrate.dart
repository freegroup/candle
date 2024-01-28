import 'package:candle/utils/featureflag.dart';
import 'package:vibration/vibration.dart';

class CandleVibrate {
  static void vibrateDuringNavigation({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
  }) {
    if (AppFeatures.vibrateDuringNavigation.isEnabled) {
      Vibration.vibrate(
          duration: duration,
          repeat: repeat,
          pattern: pattern,
          intensities: intensities,
          amplitude: amplitude);
    }
  }

  static void vibrateCompass({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
  }) {
    if (AppFeatures.vibrateCompass.isEnabled) {
      Vibration.vibrate(
          duration: duration,
          repeat: repeat,
          pattern: pattern,
          intensities: intensities,
          amplitude: amplitude);
    }
  }
}
