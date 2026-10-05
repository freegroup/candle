import 'dart:async';

import 'package:flutter/widgets.dart';

/// Stops the screen reader when a screen or dialog opens, closes or is replaced:
/// what it was saying belongs to the screen before. The new screen's title gets
/// the focus first (see CandleAppBar) and is read out instead.
class InterruptSpeechObserver extends NavigatorObserver {
  InterruptSpeechObserver(this._interrupt);

  final Future<void> Function() _interrupt;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => unawaited(_interrupt());

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => unawaited(_interrupt());

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => unawaited(_interrupt());
}
