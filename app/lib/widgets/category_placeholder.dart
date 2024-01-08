import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryPlaceholder extends StatelessWidget {
  const CategoryPlaceholder({super.key});

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
              l10n.no_location_for_category,
              style: theme.textTheme.headlineLarge,
            ),
          ],
        ),
      ),
    );
  }
}
