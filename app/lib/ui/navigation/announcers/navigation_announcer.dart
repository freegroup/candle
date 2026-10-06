import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/accessibility/accessibility_service.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/navigation/announcers/detailed_style.dart';
import 'package:candle/ui/navigation/announcers/short_style.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// The styles the user can choose from in the settings; the first one is the default.
const List<NavigationStyle> allNavigationStyles = [DetailedStyle(), ShortStyle()];

/// The style with [id], the default one for null or an unknown id.
NavigationStyle navigationStyleFor(String? id) =>
    allNavigationStyles.firstWhere((style) => style.id == id, orElse: () => allNavigationStyles.first);

/// Announces a navigation in the style the user chose in the settings
/// ([SettingsRepository.navigationStyleId]). The screen only hands over the
/// guidance; which style announces it and how is decided here.
class NavigationAnnouncer {
  NavigationAnnouncer({
    required SettingsRepository settingsRepository,
    required VibrationService vibrationService,
    required AccessibilityService accessibilityService,
  })  : _settings = settingsRepository,
        _vibration = vibrationService,
        _accessibility = accessibilityService;

  final SettingsRepository _settings;
  final VibrationService _vibration;
  final AccessibilityService _accessibility;

  /// Announces every guidance of [guidance] until it ends; the screen reader
  /// speaks with the texts and the view of [context].
  void follow(BuildContext context, Stream<NavigationGuidance> guidance) {
    final style = navigationStyleFor(_settings.navigationStyleId);
    final output = NavigationOutput(
      context: context,
      vibrationService: _vibration,
      accessibilityService: _accessibility,
    );
    guidance.listen((guidance) => style.announce(guidance, output));
  }
}

/// One way to announce a navigation.
abstract class NavigationStyle {
  const NavigationStyle();

  /// Stable key, stored in the settings.
  String get id;

  /// Name shown and read out in the settings, e.g. "Short".
  String name(AppLocalizations l10n);

  /// What the style says, e.g. "only meters and direction".
  String hint(AppLocalizations l10n);

  /// Decides whether and how [guidance] is announced: speak, vibrate, stop speaking.
  void announce(NavigationGuidance guidance, NavigationOutput output);
}

/// What a [NavigationStyle] can do to guide the user.
class NavigationOutput {
  NavigationOutput({
    required this._context,
    required VibrationService vibrationService,
    required AccessibilityService accessibilityService,
  })  : _vibration = vibrationService,
        _accessibility = accessibilityService;

  final BuildContext _context;
  final VibrationService _vibration;
  final AccessibilityService _accessibility;

  /// Says the text built by [text] with the screen reader, after what it says
  /// right now, or instead of it with [interrupt]. Nothing once the screen is gone.
  Future<void> say(String Function(BuildContext context) text, {bool interrupt = false}) async {
    if (interrupt) await _accessibility.interrupt();
    if (!_context.mounted) return;
    await SemanticsService.sendAnnouncement(
        View.of(_context), text(_context), Directionality.of(_context));
  }

  /// Stops what the screen reader says right now.
  Future<void> stopSpeaking() => _accessibility.interrupt();

  /// Vibrates, if the user did not turn vibration during the navigation off.
  Future<void> vibrate({int duration = 100, int repeat = -1}) =>
      _vibration.navigation(duration: duration, repeat: repeat);
}
