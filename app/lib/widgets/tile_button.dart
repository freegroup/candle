import 'package:candle/utils/shadow.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: createShadow(),
        border: Border.all(width: 1.0), // Use primary color for border
        borderRadius: BorderRadius.circular(8.0), // Adjust radius for roundness
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double iconSize = constraints.maxHeight / 2;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: iconSize, width: iconSize, child: icon),
                const SizedBox(height: 8), // Adjust spacing as needed
                Semantics(
                    label: talkback,
                    child: ExcludeSemantics(
                        child: Text(
                      title,
                      textScaleFactor: 1.5,
                    ))),
              ],
            );
          },
        ),
      ),
    );
  }
}
