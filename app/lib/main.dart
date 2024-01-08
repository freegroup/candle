import 'package:candle/services/poi_provider.dart';
import 'package:candle/widgets/permission_check_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/theme_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeoServiceProvider()),
        ChangeNotifierProvider(create: (_) => PoiProvider()),
      ],
      child: MaterialApp(
        title: 'Candle Navigation',
        debugShowCheckedModeBanner: false,
        theme: CThemeData.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PermissionsCheckWidget(),
      ),
    ));
  });
}
