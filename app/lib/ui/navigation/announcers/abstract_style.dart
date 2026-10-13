import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/data/services/tts/tts.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// One way to announce a navigation.
abstract class NavigationStyle {
  const NavigationStyle();

  /// Stable key, stored in the settings.
  String get id;

  /// Name shown and read out in the settings, e.g. "Short".
  String name(AppLocalizations l10n);

  /// What the style says, e.g. "only meters and direction".
  String hint(AppLocalizations l10n);

  /// Decides whether and how [guidance] is announced: speak (after what is said
  /// right now, or instead of it after [TTS.interrupt]), vibrate, stop speaking.
  /// The texts are built with [context].
  Future<void> announce(NavigationGuidance guidance, BuildContext context);

  /// Like [VibrationService.pulse], but only if the user did not turn vibration
  /// during the navigation off in the settings, which are read with [context].
  /// A style that respects the setting vibrates with this.
  Future<void> pulse(
    BuildContext context, {
    int duration = 500,
    int repeat = -1,
    List<int> pattern = const [],
  }) async {
    final settings = context.read<SettingsRepository>();
    if (settings.isEnabled(Setting.vibrateDuringNavigation)) {
      await VibrationService.pulse(duration: duration, repeat: repeat, pattern: pattern);
    }
  }
}
