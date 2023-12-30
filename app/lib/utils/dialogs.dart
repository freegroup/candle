import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showLoadingDialog(BuildContext context) {
  AppLocalizations l10n = AppLocalizations.of(context)!;
  ThemeData theme = Theme.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: theme.cardColor,
        child: Semantics(
          label: l10n.label_common_loading_t,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(width: 20),
                ExcludeSemantics(
                  child: Text(
                    l10n.label_common_loading,
                    style: TextStyle(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
