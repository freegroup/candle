import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/core/widgets/compass_rose.dart';
import 'package:flutter/material.dart';

/// A compass rose with the phone's direction at the top, next to a large [title] (e.g. the
/// compass direction) and a [subtitle]. Shows sighted and low vision users that
/// the screen depends on where the phone points.
///
/// Display only: the heading comes from the view model.
class CompassHeadingSmall extends StatelessWidget {
  const CompassHeadingSmall({
    super.key,
    required this.heading,
    required this.title,
    required this.subtitle,
    this.dimmed = false,
    this.warning = false,
  });

  /// Clockwise degrees from north the phone points to.
  final int heading;
  final String title;
  final String subtitle;

  /// The text is not current, e.g. the phone is between two directions.
  final bool dimmed;

  /// Something keeps the heading from being right, e.g. the phone is tilted.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var color = warning ? theme.negativeColor : theme.primaryColor;
    if (dimmed && !warning) color = color.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.primaryColor.withAlpha(60))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          CompassRose(heading: heading, color: color),
          const SizedBox(width: 18),
          Expanded(
            // large system fonts shrink the text instead of cutting it off
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineMedium!.copyWith(color: color)),
                  Text(subtitle, style: theme.textTheme.titleMedium!.copyWith(color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
