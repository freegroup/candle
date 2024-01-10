import 'package:flutter/material.dart';

class TwolinerWidget extends StatefulWidget {
  final String headlineTalkback;
  final String headline;

  final String subtitleTalkback;
  final String subtitle;
  final Color? color;

  const TwolinerWidget({
    super.key,
    this.color,
    required this.headline,
    required this.headlineTalkback,
    required this.subtitle,
    required this.subtitleTalkback,
  });

  @override
  State<TwolinerWidget> createState() => _TwolinerWidgetState();
}

class _TwolinerWidgetState extends State<TwolinerWidget> {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color color = widget.color ?? theme.primaryColor;
    return Expanded(
      child: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              child: Semantics(
                label: widget.headlineTalkback,
                child: ExcludeSemantics(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.headline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall!.copyWith(color: color),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              child: Semantics(
                label: widget.subtitleTalkback,
                child: ExcludeSemantics(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall!.copyWith(color: color),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
