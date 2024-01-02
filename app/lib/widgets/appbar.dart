import 'package:flutter/material.dart';

class CandleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String talkback;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget>? actions;
  final double height;

  const CandleAppBar({
    super.key,
    required this.talkback,
    this.title,
    this.subtitle,
    this.actions,
    this.height = kToolbarHeight * 1.2,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: talkback,
      child: ExcludeSemantics(
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null) title!,
                if (subtitle != null) subtitle!,
              ],
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: actions,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Theme.of(context).appBarTheme.titleTextStyle?.color?.withAlpha(50),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
