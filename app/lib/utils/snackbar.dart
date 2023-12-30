import 'package:flutter/material.dart';

void showSnackbar(BuildContext context, String message) {
  print(message);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ),
  );
}

void showSnackbarAndNavigateBack(BuildContext context, String message) {
  var mediaQueryData = MediaQuery.of(context);
  bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;
  Duration duration = const Duration(seconds: 3);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
    ),
  );

  if (isScreenReaderEnabled) {
    // give the screen reader some time to speak out the snack bar
    Future.delayed(duration, () {
      Navigator.pop(context);
    });
  } else {
    Navigator.pop(context);
  }
}
