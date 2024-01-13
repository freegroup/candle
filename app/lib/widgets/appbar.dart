import 'package:flutter/material.dart';

class CandleAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String talkback;
  final Widget? title;

  final Widget? subtitle;
  final List<Widget>? actions;

  const CandleAppBar({
    super.key,
    required this.talkback,
    this.title,
    this.subtitle,
    this.actions,
  });

  @override
  State<CandleAppBar> createState() => _CandleAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.4);
}

class _CandleAppBarState extends State<CandleAppBar> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.talkback,
      child: ExcludeSemantics(
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (widget.title != null) widget.title!,
                if (widget.subtitle != null) widget.subtitle!,
              ],
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: widget.actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Theme.of(context).appBarTheme.titleTextStyle?.color?.withAlpha(50),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
