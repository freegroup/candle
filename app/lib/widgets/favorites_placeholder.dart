import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class FavoritesPlaceholder extends StatelessWidget {
  const FavoritesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: MergeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to the start
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.favorites_placeholder_intro,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            MarkdownBody(data: l10n.favorites_placeholder_tip_title),
            const SizedBox(height: 20),
            Text(
              l10n.favorites_placeholder_final_message,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
