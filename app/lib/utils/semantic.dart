import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:candle/l10n/app_localizations.dart';

mixin SemanticAnnouncer<T extends StatefulWidget> on State<T> {
  
  void announceOnShow(String title) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    var speak = l10n.screen_show_announcement_t(title);
    // wait a little bit to give the talkback of the "back button" is spoken...
    // then we can announce which screen is shown.
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    SemanticsService.sendAnnouncement(View.of(context), speak, TextDirection.ltr);
  }
}
