import 'dart:async';

import 'package:candle/config/app_config.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:flutter/material.dart';

typedef _SnackBarController = ScaffoldFeatureController<SnackBar, SnackBarClosedReason>;

/// The [sticky] snack bar on screen, null when none is shown.
_SnackBarController? _sticky;

/// Shows [message] at the bottom of the screen for [SnackbarConfig.duration]; a tap closes it.
///
/// A [sticky] message replaces the one on screen and, without a screen reader,
/// stays until it is tapped, the next message comes or the user leaves the screen
/// it was shown on.
void showSnackbar(BuildContext context, String message, {bool sticky = false}) {
  log.d(message);
  ThemeData theme = Theme.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (sticky || _sticky != null) messenger.removeCurrentSnackBar();

  final foreground = theme.cardColor;

  final controller = messenger.showSnackBar(
    SnackBar(
      backgroundColor: theme.primaryColor,
      // a tap anywhere closes it; the X only marks the messages that stay
      content: MergeSemantics(
        child: Semantics(
          onTap: messenger.hideCurrentSnackBar,
          onTapHint: AppLocalizations.of(context)?.button_common_close,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: messenger.hideCurrentSnackBar,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold, color: foreground),
                    ),
                  ),
                  if (sticky)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ExcludeSemantics(child: Icon(Icons.close, size: 32, color: foreground)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      duration: SnackbarConfig.duration,
      persist: sticky && !MediaQuery.accessibleNavigationOf(context),
      behavior: SnackBarBehavior.floating,
    ),
  );
  if (!sticky) return;

  _sticky = controller;
  unawaited(controller.closed.then((_) {
    if (_sticky == controller) _sticky = null;
  }));
  final route = ModalRoute.of(context);
  if (route != null) {
    unawaited(route.popped.then((_) {
      if (_sticky == controller) messenger.removeCurrentSnackBar();
    }));
  }
}

void showSnackbarAndNavigateBack(BuildContext context, String message) {
  showSnackbar(context, message);

  var mediaQueryData = MediaQuery.of(context);
  bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

  if (isScreenReaderEnabled) {
    // give the screen reader some time to speak out the snack bar
    Future<void>.delayed(SnackbarConfig.duration, () {
      if (context.mounted) Navigator.pop(context);
    });
  } else {
    Navigator.pop(context);
  }
}
