import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ScrollingInfoPage extends StatelessWidget {
  final String header;
  final String body;
  final Widget? decoration;

  const ScrollingInfoPage({super.key, required this.header, required this.body, this.decoration});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * (2 / 7);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(26.0),
      child: MergeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to the start
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(header, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 20),
            MarkdownBody(data: body),
            const SizedBox(height: 20),
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
