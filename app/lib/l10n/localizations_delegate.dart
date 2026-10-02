import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/l10n/gen/short_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Loads the texts of the app: the short ones for experienced screen reader users
/// if [short] is set, otherwise the full ones. Screens just use AppLocalizations
/// and never know which version they get.
class CandleLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const CandleLocalizationsDelegate({required this.short});

  final bool short;

  @override
  bool isSupported(Locale locale) => AppLocalizations.delegate.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final texts = short ? shortLocalizations(locale.languageCode) : null;
    return texts == null ? AppLocalizations.delegate.load(locale) : SynchronousFuture(texts);
  }

  @override
  bool shouldReload(CandleLocalizationsDelegate old) => old.short != short;
}
