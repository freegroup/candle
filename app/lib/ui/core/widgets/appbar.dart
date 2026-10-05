import 'package:candle/ui/location_notes/widgets/new_location_note_here.dart';
import 'package:candle/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/foundation.dart';
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
  final _titleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // A new screen or tab starts with the screen reader on its title, which is read out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleKey.currentContext?.findRenderObject()?.sendSemanticsEvent(const FocusSemanticEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    // TalkBack puts its focus on the first element when a screen opens: that is the
    // title, so the user hears where they are at once (and the speech about the
    // previous screen stops). The back button and the actions follow.
    List<Widget> actions = [
      for (final action in [
        if (widget.settingsEnabled) _buildSettingsButton(context),
        ...?widget.actions,
      ])
        Semantics(container: true, sortKey: const OrdinalSortKey(2), child: action),
    ];

    final route = ModalRoute.of(context);
    final leading = (route?.impliesAppBarDismissal ?? false)
        ? Semantics(
            container: true,
            sortKey: const OrdinalSortKey(1),
            child: route is PageRoute && route.fullscreenDialog
                ? const CloseButton()
                : const BackButton(),
          )
        : null;

    return AppBar(
      leading: leading,
      // the title marks itself as header and screen name, so it sits next to the back
      // button in the semantics tree and its sort key counts
      excludeHeaderSemantics: true,
      title: Semantics(
        key: _titleKey,
        header: true,
        namesRoute: defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? null
            : true,
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
