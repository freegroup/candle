import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

mixin SemanticAnnouncer<T extends StatefulWidget> on State<T> {
  /// Whether this screen is the one on top. A screen covered by another one
  /// gives no announcements or vibrations: they would talk over the screen on top.
  bool get isOnTop => ModalRoute.isCurrentOf(context) ?? true;

  void announceOnShow(String title) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    var speak = l10n.screen_show_announcement_t(title);
    // wait a little bit to give the talkback of the "back button" is spoken...
    // then we can announce which screen is shown.
    await Future<void>.delayed(const Duration(milliseconds: 3000));
    if (!mounted || !isOnTop) return;
    await SemanticsService.sendAnnouncement(View.of(context), speak, TextDirection.ltr);
  }
}
