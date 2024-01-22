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
    double imageWidth = screenWidth * (3 / 7);

    MarkdownStyleSheet markdownStyle = MarkdownStyleSheet(
      p: theme.textTheme.bodyLarge,
    );

    return MergeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed header
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
          Container(color: theme.primaryColor.withAlpha(30), height: 1.0),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MarkdownBody(
                      data: body,
                      styleSheet: markdownStyle,
                    ),
                    const SizedBox(height: 50),
                    Center(
                      child: SizedBox(
                        width: imageWidth,
                        child: decoration,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
