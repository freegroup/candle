import 'package:flutter/material.dart';

/// The large, full-width action button of the app. [outlined] marks a secondary
/// action next to a primary one; screen readers announce [talkback] instead of [label].
class DialogButton extends StatelessWidget {
  final VoidCallback onTab;
  final String label;
  final String talkback;
  final bool outlined;

  const DialogButton({
    super.key,
    required this.label,
    required this.onTab,
    required this.talkback,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)));
    const padding = EdgeInsets.symmetric(vertical: 15);
    const minimumSize = Size(double.infinity, 48);
    final text = theme.textTheme.headlineMedium!;

    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40, top: 30, bottom: 15),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Semantics(
          button: true,
          label: talkback,
          excludeSemantics: true,
          onTap: onTab,
          child: outlined
              ? OutlinedButton(
                  onPressed: onTab,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor, width: 2),
                    padding: padding,
                    shape: shape,
                    minimumSize: minimumSize,
                  ),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: text.copyWith(color: theme.primaryColor)),
                )
              : ElevatedButton(
                  onPressed: onTab,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.cardColor,
                    padding: padding,
                    shape: shape,
                    minimumSize: minimumSize,
                  ),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: text.copyWith(color: theme.cardColor)),
                ),
        ),
      ),
    );
  }
}
