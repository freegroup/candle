import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TargetReachedWidget extends StatelessWidget {
  const TargetReachedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
              child: Icon(
            Icons.done_rounded,
            size: 40,
            color: theme.primaryColor,
          )),
          const SizedBox(width: 10),
          Text(
            l10n.location_reached,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          )
        ],
      ),
    );
  }
}
