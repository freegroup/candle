import 'package:candle/ui/location_notes/widgets/new_location_note_here.dart';
import 'package:candle/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

class CandleAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String talkback;
  final Widget? title;
  final Widget? subtitle;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool settingsEnabled;

  /// Whether the screen reader offers the action "add location note here" on the title.
  final bool offerNewLocationNote;
  const CandleAppBar(
      {super.key,
      required this.talkback,
      this.title,
      this.subtitle,
      this.actions,
      this.bottom,
      this.settingsEnabled = false,
      this.offerNewLocationNote = true});

  @override
  State<CandleAppBar> createState() => _CandleAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight * 1.4 + (bottom == null ? 0 : 40));
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
        header: true,
        sortKey: const OrdinalSortKey(0),
        label: widget.talkback,
        customSemanticsActions: widget.offerNewLocationNote
            ? {
                CustomSemanticsAction(label: AppLocalizations.of(context)!.location_note_add_here):
                    () => openNewLocationNoteHere(context),
              }
            : null,
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
      bottom: widget.bottom != null
          ? widget.bottom!
          : PreferredSize(
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
              MaterialPageRoute<void>(builder: (context) => buildSettingsScreen()),
            );
          },
        ),
      ),
    );
  }
}
