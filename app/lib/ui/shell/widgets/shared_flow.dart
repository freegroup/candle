import 'package:flutter/material.dart';

/// The route name of the shared-content preview flow: the shared place or note
/// screen, the edit screen opened from it, and the target compass. A new shared
/// link clears every route with this name before showing the new one, so only
/// one such preview is ever on the stack. The running map navigation does not
/// carry this name and therefore stays.
const sharedFlowRouteName = 'shared-flow';

/// A route of the shared-content flow (its screen carries [sharedFlowRouteName]),
/// so a later screen opened from the preview is cleared with it.
MaterialPageRoute<void> sharedFlowRoute(Widget screen) => MaterialPageRoute<void>(
      builder: (_) => screen,
      settings: const RouteSettings(name: sharedFlowRouteName),
    );

/// Shows [screen] as the shared-content preview, first clearing a previous
/// preview (and the screens opened from it), so only one is ever on the stack.
void showSharedContent(NavigatorState navigator, Widget screen) {
  navigator.popUntil((route) => route.settings.name != sharedFlowRouteName);
  navigator.push(sharedFlowRoute(screen));
}
