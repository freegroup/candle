import 'package:candle/screens/navigator.dart';
import 'package:candle/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CandleApp extends StatefulWidget {
  const CandleApp({super.key});

  @override
  State<CandleApp> createState() => _AppState();
}

class _AppState extends State<CandleApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return MaterialApp(
        title: 'Candle Navigation',
        debugShowCheckedModeBanner: false,
        theme: CThemeData.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NavigatorScreen(),
        //home: const AddressSearchScreen2(),
      );
    });
  }
}
