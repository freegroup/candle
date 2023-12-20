import 'package:flutter/material.dart';

class TileButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final String talkback;
  final Widget icon;

  const TileButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.talkback,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxHeight / 2;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: iconSize, width: iconSize, child: icon),
              const SizedBox(height: 8), // Adjust spacing as needed
              Semantics(label: talkback, child: ExcludeSemantics(child: Text(title))),
            ],
          );
        },
      ),
    );
  }
}
