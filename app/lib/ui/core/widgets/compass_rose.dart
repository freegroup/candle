import 'dart:math';

import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A compass rose with the phone's direction at the top: the arrow always points
/// up (where the phone points), the rose turns so that N shows the real north.
///
/// The letters keep standing upright: each one turns around its own center.
class CompassRose extends StatelessWidget {
  const CompassRose({super.key, required this.heading, required this.color, this.size = 72});

  /// Clockwise degrees from north the phone points to.
  final int heading;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RosePainter(
          heading: heading,
          color: color,
          letters: [
            l10n.compass_letter_north,
            l10n.compass_letter_east,
            l10n.compass_letter_south,
            l10n.compass_letter_west,
          ],
        ),
      ),
    );
  }
}

/// Where the center of the label of [direction] (degrees clockwise from north) is,
/// relative to the center of the rose, when the phone points to [heading].
/// Screen coordinates: x to the right, y down.
Offset compassLabelPosition({required num direction, required num heading, required double radius}) {
  final angle = (direction - heading) * pi / 180;
  return Offset(sin(angle) * radius, -cos(angle) * radius);
}

/// Size of the arrow relative to the rose.
const _arrowScale = 0.8;

class _RosePainter extends CustomPainter {
  _RosePainter({required this.heading, required this.color, required this.letters});

  final int heading;
  final Color color;

  /// North, east, south, west.
  final List<String> letters;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 1, line);

    // a tick every 45°, the long ones at the four letters
    for (var direction = 0; direction < 360; direction += 45) {
      final outer = compassLabelPosition(direction: direction, heading: heading, radius: radius - 1);
      final inner = compassLabelPosition(
          direction: direction, heading: heading, radius: radius * (direction % 90 == 0 ? 0.8 : 0.88));
      canvas.drawLine(center + inner, center + outer, line);
    }

    for (var i = 0; i < 4; i++) {
      final isNorth = i == 0;
      final text = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: TextStyle(
            color: color,
            fontSize: radius * (isNorth ? 0.42 : 0.3),
            fontWeight: isNorth ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // The center of the letter is the pivot: moved along the rotated circle,
      // the letter itself keeps standing upright.
      final letterCenter =
          center + compassLabelPosition(direction: i * 90, heading: heading, radius: radius * 0.58);
      text.paint(canvas, letterCenter - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }

    // the fixed arrow: the direction the phone points to; small enough to leave
    // the letters of the rose visible
    final a = radius * _arrowScale;
    final arrow = Path()
      ..moveTo(center.dx, center.dy - a * 0.5)
      ..lineTo(center.dx + a * 0.2, center.dy + a * 0.15)
      ..lineTo(center.dx, center.dy + a * 0.02)
      ..lineTo(center.dx - a * 0.2, center.dy + a * 0.15)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RosePainter old) =>
      old.heading != heading || old.color != color || !listEquals(old.letters, letters);
}
