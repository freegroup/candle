import 'package:flutter/material.dart';

class TileButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final String talkback;
  final Widget icon;
  final double borderRadius = 10;

  const TileButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.talkback,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 1.0],
          colors: [
            const Color.fromARGB(255, 10, 10, 10),
            theme.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          )),
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shadowColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: onPressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double iconSize = constraints.maxHeight / 2;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: iconSize, width: iconSize, child: icon),
                const SizedBox(height: 8),
                Semantics(
                    label: talkback,
                    child: ExcludeSemantics(child: Text(title, textScaleFactor: 1.3))),
              ],
            );
          },
        ),
      ),
    );
  }
}
