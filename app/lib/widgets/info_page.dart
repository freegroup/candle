import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class GenericInfoPage extends StatelessWidget {
  final String header;
  final String body;
  final Widget? decoration;

  const GenericInfoPage({super.key, required this.header, required this.body, this.decoration});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * (2 / 7);

    MarkdownStyleSheet markdownStyle = MarkdownStyleSheet(
      p: theme.textTheme.bodyLarge,
      // Add other custom styles if needed
    );

    return SingleChildScrollView(
      //padding: const EdgeInsets.all(26.0),
      child: MergeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to the start
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  header,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: MarkdownBody(
                data: body,
                styleSheet: markdownStyle,
              ),
            ),
            const SizedBox(height: 50),
            Container(
              width: imageWidth,
              alignment: Alignment.center,
              child: decoration,
            ),
          ],
        ),
      ),
    );
  }
}
