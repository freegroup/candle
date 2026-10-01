import 'package:flutter/material.dart';

class DialogButton extends StatelessWidget {
  final VoidCallback onTab;
  final String label;
  final String talkback;

  const DialogButton({
    super.key,
    required this.label,
    required this.onTab,
    required this.talkback,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40, top: 30, bottom: 15),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ElevatedButton(
          onPressed: onTab,
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.cardColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              minimumSize: const Size(double.infinity, 48)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium!.copyWith(color: theme.cardColor),
          ),
        ),
      ),
    );
  }
}
