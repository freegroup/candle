import 'package:candle/utils/global_logger.dart';
import 'package:flutter/material.dart';

const kDuration = Duration(seconds: 3);

void showSnackbar(BuildContext context, String message) {
  log.d(message);
  ThemeData theme = Theme.of(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: theme.primaryColor,
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: theme.cardColor),
        ),
      ),
      duration: kDuration,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showSnackbarAndNavigateBack(BuildContext context, String message) {
  showSnackbar(context, message);

  var mediaQueryData = MediaQuery.of(context);
  bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

  if (isScreenReaderEnabled) {
    // give the screen reader some time to speak out the snack bar
    Future.delayed(kDuration, () {
      Navigator.pop(context);
    });
  } else {
    Navigator.pop(context);
  }
}
