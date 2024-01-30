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

    return Semantics(
      label: talkback,
      button: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(left: 40, right: 40, top: 30, bottom: 5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: onTab,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium!.copyWith(color: theme.cardColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
