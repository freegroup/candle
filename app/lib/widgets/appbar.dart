import 'package:flutter/material.dart';

class CandleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String talkback;
  final Widget? title;
  final List<Widget>? actions;
  final double height;

  const CandleAppBar({
    super.key,
    required this.talkback,
    this.title,
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
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: actions,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Theme.of(context).appBarTheme.titleTextStyle?.color?.withAlpha(50),
              height: 1.0,
            ),
          ),
          // Add other properties if needed
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
