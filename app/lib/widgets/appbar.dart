import 'package:flutter/material.dart';

class CandleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? talkback;
  final Widget? title;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final double height;

  const CandleAppBar({
    super.key,
    required this.talkback,
    this.title,
    this.backgroundColor,
    this.actions,
    this.height = kToolbarHeight, // Default AppBar height
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: talkback,
      child: ExcludeSemantics(
        child: AppBar(
          title: title,
          backgroundColor: backgroundColor,
          actions: actions,
          // Add other properties if needed
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
