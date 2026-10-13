import 'package:flutter/material.dart';

class SemanticHeader extends StatelessWidget {
  final String title;
  final String talkback;

  /// Called when the screen reader focus enters and leaves the header.
  final VoidCallback? onScreenReaderFocus;
  final VoidCallback? onScreenReaderFocusLost;

  const SemanticHeader({
    super.key,
    required this.title,
    required this.talkback,
    this.onScreenReaderFocus,
    this.onScreenReaderFocusLost,
  });

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

    return isScreenReaderEnabled
        ? Semantics(
            label: talkback,
            onDidGainAccessibilityFocus: onScreenReaderFocus,
            onDidLoseAccessibilityFocus: onScreenReaderFocusLost,
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
