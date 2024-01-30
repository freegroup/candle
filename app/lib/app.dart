import 'package:candle/theme_data.dart';
import 'package:candle/widgets/permission_check_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      home: const PermissionsCheckWidget(),
    );
  }
}
