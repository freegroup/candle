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
    return Semantics(
      label: talkback,
      child: InkWell(
        onTap: onTab,
        child: Container(
          width: buttonWidth,
          height: buttonWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: createShadow(),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).primaryColor, width: 1.0),
          ),
          child: Icon(
            icons,
            size: buttonWidth,
            color: Theme.of(context).primaryColor,
          ), // 'X' icon
        ),
      ),
    );
  }
}
