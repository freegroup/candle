import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';

class DividedWidget extends StatelessWidget {
  final Widget top;
  final Widget bottom;
  final double fraction;
  final double corner = 50;
  final int topBorder = 15;

  const DividedWidget({required this.top, required this.bottom, required this.fraction, super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    // Generate Positioned elements for the shadow effect
    List<Widget> generateShadowElements(int topBorder) {
      return [
        ...List.generate(topBorder, (index) {
          double opacity = (topBorder - index) * 0.001; // Adjust opacity for each layer
          return Positioned(
            left: -(index).toDouble(),
            right: -(index).toDouble(),
            bottom: 0,
            top: fraction - corner - index,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(corner + index),
                topRight: Radius.circular(corner + index),
              ),
              child: Container(color: theme.primaryColor.withOpacity(opacity)),
            ),
          );
        }),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: fraction - corner - 1,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(corner),
              topRight: Radius.circular(corner),
            ),
            child: Container(color: Colors.black),
          ),
        )
      ];
    }

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
          ...generateShadowElements(topBorder),
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
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 1.0],
                    colors: [
                      Color.fromARGB(255, 2, 2, 2),
                      Color.fromARGB(255, 9, 9, 9),
                    ],
                  ),
                ),
                child: bottom,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
