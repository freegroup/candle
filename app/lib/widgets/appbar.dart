import 'package:candle/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CandleAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String talkback;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget>? actions;
  final bool settingsEnabled;
  const CandleAppBar(
      {super.key,
      required this.talkback,
      this.title,
      this.subtitle,
      this.actions,
      this.settingsEnabled = false});

  @override
  State<CandleAppBar> createState() => _CandleAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.4);
}

class _CandleAppBarState extends State<CandleAppBar> {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    List<Widget> actions = widget.settingsEnabled
        ? [_buildSettingsButton(context), ...?widget.actions]
        : [...?widget.actions];

    return AppBar(
      title: Semantics(
        label: widget.talkback,
        child: ExcludeSemantics(
          child: Padding(
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
        ),
      ),
      backgroundColor: theme.appBarTheme.backgroundColor,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: theme.primaryColor.withAlpha(60),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.button_settings_t,
      button: true,
      child: ExcludeSemantics(
        child: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ),
    );
  }
}
