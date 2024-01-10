import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryPlaceholder extends StatelessWidget {
  const CategoryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: MergeSemantics(
            child: Text(
              l10n.no_location_for_category,
              style: theme.textTheme.headlineLarge,
            ),
          ),
        ),
      ),
    );
  }
}
