import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A named colour profile the user can pick in the settings.
///
/// Kept deliberately small for now (foreground + background). More attributes
/// will live here later so screens can read them from the active theme, e.g. a
/// `compact` flag to drop or rearrange parts of a layout, or a font scale.
class CandleTheme {
  const CandleTheme({
    required this.id,
    required this.name,
    required this.hint,
    required this.tint,
    required this.bg,
  });

  /// Stable key, stored in the settings.
  final String id;

  /// Name shown and read out in the settings, e.g. "Yellow on black".
  final String Function(AppLocalizations l10n) name;

  /// Who the profile suits, e.g. "good for light sensitivity".
  final String Function(AppLocalizations l10n) hint;

  /// Foreground / accent colour: text, icons, borders.
  final Color tint;

  /// Background colour of the whole app.
  final Color bg;
}

/// The built-in profiles. The first entry is the default (today's look), so a
/// user who never opens the setting keeps gold on black.
final List<CandleTheme> candleThemes = [
  CandleTheme(
    id: 'amber_dark',
    name: (l10n) => l10n.theme_amber_dark,
    hint: (l10n) => l10n.theme_amber_dark_hint,
    tint: const Color(0xFFFFC004),
    bg: const Color(0xFF000000),
  ),
  CandleTheme(
    id: 'white_dark',
    name: (l10n) => l10n.theme_white_dark,
    hint: (l10n) => l10n.theme_white_dark_hint,
    tint: const Color(0xFFFFFFFF),
    bg: const Color(0xFF000000),
  ),
  CandleTheme(
    id: 'black_light',
    name: (l10n) => l10n.theme_black_light,
    hint: (l10n) => l10n.theme_black_light_hint,
    tint: const Color(0xFF000000),
    bg: const Color(0xFFFFFFFF),
  ),
  CandleTheme(
    id: 'blue_yellow',
    name: (l10n) => l10n.theme_blue_yellow,
    hint: (l10n) => l10n.theme_blue_yellow_hint,
    tint: const Color(0xFF00315C),
    bg: const Color(0xFFFFD400),
  ),
];
