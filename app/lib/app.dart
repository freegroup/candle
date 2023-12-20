import 'package:candle/screens/screens.dart';
import 'package:candle/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CandleApp extends StatelessWidget {
  const CandleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: CThemeData.darkTheme,
      initialRoute: "$HomeScreen",
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        "$HomeScreen": (context) => const HomeScreen(),
        "$FavoriteScreen": (context) => const FavoriteScreen(),
        "$SettingsScreen": (context) => const SettingsScreen(),
      },
    );
  }
}
