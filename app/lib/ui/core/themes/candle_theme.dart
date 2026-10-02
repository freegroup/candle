import 'package:flutter/material.dart';

/// A named colour profile the user can pick in the settings.
///
/// Kept deliberately small for now (foreground + background). More attributes
/// will live here later so screens can read them from the active theme, e.g. a
/// `compact` flag to drop or rearrange parts of a layout, or a font scale.
class CandleTheme {
  const CandleTheme({required this.id, required this.tint, required this.bg});

  /// Stable key; also the l10n key for the name (`theme_<id>`) and the hint
  /// (`theme_<id>_hint`), and the value stored in the settings.
  final String id;

  /// Foreground / accent colour: text, icons, borders.
  final Color tint;

  /// Background colour of the whole app.
  final Color bg;
}

/// The built-in profiles. The first entry is the default (today's look), so a
/// user who never opens the setting keeps gold on black.
const List<CandleTheme> candleThemes = [
  CandleTheme(id: 'amber_dark', tint: Color(0xFFFFC004), bg: Color(0xFF000000)),
  CandleTheme(id: 'white_dark', tint: Color(0xFFFFFFFF), bg: Color(0xFF000000)),
  CandleTheme(id: 'black_light', tint: Color(0xFF000000), bg: Color(0xFFFFFFFF)),
  CandleTheme(id: 'blue_yellow', tint: Color(0xFF00315C), bg: Color(0xFFFFD400)),
];
