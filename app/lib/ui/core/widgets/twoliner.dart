import 'package:flutter/material.dart';

/// A big headline over a smaller subtitle, centred, used in the compass panes.
///
/// The subtitle (e.g. the distance) always keeps its size. The headline (e.g. a
/// place name or address) wraps to two lines and is then cut with an ellipsis;
/// only if two lines still do not fit does it shrink, so a long address can
/// never make the subtitle tiny.
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
    final ThemeData theme = Theme.of(context);
    final Color color = widget.color ?? theme.primaryColor;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: widget.headlineTalkback,
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        // bound the width so the text wraps to two lines before
                        // the ellipsis, instead of shrinking to one tiny line
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth - 24),
                        child: Text(
                          widget.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall!.copyWith(color: color),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                label: widget.subtitleTalkback,
                child: ExcludeSemantics(
                  child: Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall!.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
