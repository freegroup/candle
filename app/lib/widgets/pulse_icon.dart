import 'package:flutter/material.dart';
import 'package:candle/theme_data.dart';

class PulsingRecordIcon extends StatefulWidget {
  const PulsingRecordIcon({super.key});

  @override
  State<PulsingRecordIcon> createState() => _PulsingRecordIconState();
}

class _PulsingRecordIconState extends State<PulsingRecordIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _animation,
          child: Icon(
            Icons.fiber_manual_record,
            color: theme.negativeColor,
            size: 50.0,
          ),
        ),
        Text(
          "Recording",
          style: theme.textTheme.bodyLarge!
              .copyWith(color: theme.negativeColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
