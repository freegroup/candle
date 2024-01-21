import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';

class TextOverlayScreen extends StatelessWidget {
  final String text;

  const TextOverlayScreen({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Close the screen on tap
      child: SafeArea(
        child: BackgroundWidget(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              text,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
