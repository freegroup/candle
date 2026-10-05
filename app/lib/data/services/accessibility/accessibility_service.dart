import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Screen reader controls the Flutter semantics API does not offer, via the
/// native channel `candle/accessibility` (AccessibilityChannel.kt).
class AccessibilityService {
  AccessibilityService({TargetPlatform? platform}) : _platform = platform ?? defaultTargetPlatform;

  static const _channel = MethodChannel('candle/accessibility');

  final TargetPlatform _platform;

  /// Stops what the screen reader says right now, e.g. an outdated announcement
  /// before a new one. Android only; without a running screen reader it does nothing.
  Future<void> interrupt() async {
    if (_platform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('interrupt');
    } on PlatformException catch (e) {
      _log.w('Interrupting the screen reader failed: $e');
    } on MissingPluginException catch (e) {
      _log.w('Interrupting the screen reader failed: $e');
    }
  }
}
