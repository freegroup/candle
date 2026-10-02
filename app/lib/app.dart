import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/l10n/localizations_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:candle/ui/onboarding/widgets/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

class CandleApp extends StatelessWidget {
  const CandleApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    // Rebuilt when a setting changes, so switching to short texts reloads all texts.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
      title: 'Candle Navigation',
      debugShowCheckedModeBanner: false,
      theme: CThemeData.darkTheme,
      localizationsDelegates: [
        CandleLocalizationsDelegate(short: settings.isEnabled(Setting.shortTalkback)),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Android 15+ draws the app edge-to-edge: keep every screen above the system
      // navigation bar so no button or list entry ends up hidden behind it.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(top: false, left: false, right: false, child: child!),
      ),
      home: buildOnboarding(),
      ),
    );
  }
}
