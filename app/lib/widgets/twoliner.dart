import 'package:flutter/material.dart';

class TwoLineDisplay extends StatefulWidget {
  final String headlineTalkback;
  final String headline;

  final String subtitleTalkback;
  final String subtitle;

  const TwoLineDisplay({
    super.key,
    required this.headline,
    required this.headlineTalkback,
    required this.subtitle,
    required this.subtitleTalkback,
  });

  @override
  State<TwoLineDisplay> createState() => _TwoLineDisplayState();
}

class _TwoLineDisplayState extends State<TwoLineDisplay> {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

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
                      style: theme.textTheme.displaySmall,
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
                      style: theme.textTheme.headlineSmall,
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
