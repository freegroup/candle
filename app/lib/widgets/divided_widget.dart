import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';

class DividedWidget extends StatelessWidget {
  final Widget top;
  final Widget bottom;
  final double fraction;
  final double corner = 60;
  const DividedWidget({required this.top, required this.bottom, required this.fraction, super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return BackgroundWidget(
      child: Stack(
        children: [
          // Map occupies the top 2/3 of the screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: fraction,
            child: top,
          ),
          // Bottom panel occupies the bottom 1/3 of the screen
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: fraction - corner,
            child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(corner),
                  topRight: Radius.circular(corner),
                ),
                child: Container(color: theme.cardColor, child: bottom)),
          ),
        ],
      ),
    );
  }
}
