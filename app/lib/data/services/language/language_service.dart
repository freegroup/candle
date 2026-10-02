import 'dart:ui';

import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The language the app shows, for services that request texts in it
/// (Wikipedia, address search). Follows changes of the system or app language
/// in the device settings while the app runs.
class LanguageService extends ChangeNotifier with WidgetsBindingObserver {
  LanguageService({
    List<Locale> Function()? preferredLocales,
    this._supportedLocales = AppLocalizations.supportedLocales,
  }) : _preferredLocales = preferredLocales ?? (() => PlatformDispatcher.instance.locales) {
    _languageCode = _resolve();
    WidgetsBinding.instance.addObserver(this);
  }

  final List<Locale> Function() _preferredLocales;
  final List<Locale> _supportedLocales;
  late String _languageCode;

  /// Language code of the app's texts, e.g. "de".
  String get languageCode => _languageCode;

  // The same rule MaterialApp uses to pick the language of the texts.
  String _resolve() => basicLocaleListResolution(_preferredLocales(), _supportedLocales).languageCode;

  @override
  void didChangeLocales(List<Locale>? locales) {
    final languageCode = _resolve();
    if (languageCode == _languageCode) return;
    _languageCode = languageCode;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
