import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/onboarding/widgets/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/app_localizations.dart';

class CandleApp extends StatelessWidget {
  const CandleApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candle Navigation',
      debugShowCheckedModeBanner: false,
      theme: CThemeData.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Android 15+ draws the app edge-to-edge: keep every screen above the system
      // navigation bar so no button or list entry ends up hidden behind it.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(top: false, left: false, right: false, child: child!),
      ),
      home: buildOnboarding(),
    );
  }
}
