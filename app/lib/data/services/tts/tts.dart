import 'dart:ui';

import 'package:candle/data/services/accessibility/accessibility_service.dart';
import 'package:flutter/semantics.dart';

/// Everything Candle says goes through [say], and [interrupt] stops it.
///
/// For now the text is handed to the screen reader (VoiceOver, TalkBack), which
/// speaks it; without a running screen reader nothing is said. What happens to
/// a text can be decided here later, for example an own voice while the screen
/// is locked.
abstract final class TTS {
  // Not from the providers: speech comes from everywhere, also in tests without
  // them; the service holds no state.
  static final _accessibility = AccessibilityService();

  /// Says [message].
  static Future<void> say(String message) async {
    // Candle has one window; the announcement for the screen reader belongs to its view.
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return;
    // Candle's languages (German, English) are written from left to right.
    await SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  /// Stops what is said right now, e.g. an outdated announcement before a new one.
  static Future<void> interrupt() => _accessibility.interrupt();
}
