import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ScrollingInfoPage extends StatelessWidget {
  final String header;
  final String body;

  const ScrollingInfoPage({super.key, required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: MergeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to the start
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            MarkdownBody(data: body),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
