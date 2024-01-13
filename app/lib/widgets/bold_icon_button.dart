import 'package:candle/utils/shadow.dart';
import 'package:flutter/material.dart';

class BoldIconButton extends StatelessWidget {
  final GestureTapCallback onTab;
  final IconData icons;
  final String talkback;

  const BoldIconButton({
    super.key,
    required this.buttonWidth,
    required this.onTab,
    required this.icons,
    required this.talkback,
  });

  final double buttonWidth;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Semantics(
      label: talkback,
      child: InkWell(
        onTap: onTab,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          child: Container(
            width: buttonWidth,
            height: buttonWidth,
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: createShadow(),
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryColor, width: 4.0),
            ),
            child: Icon(
              icons,
              size: buttonWidth * 0.7,
              color: theme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
