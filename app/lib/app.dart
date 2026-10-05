import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/l10n/localizations_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:candle/ui/onboarding/widgets/onboarding_screen.dart';
import 'package:candle/ui/core/widgets/report_covered.dart';
import 'package:candle/ui/core/utils/interrupt_speech_observer.dart';
import 'package:candle/data/services/accessibility/accessibility_service.dart';
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
      theme: CThemeData.theme(settings.colorTheme),
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
      navigatorObservers: [
        candleRouteObserver,
        InterruptSpeechObserver(context.read<AccessibilityService>().interrupt),
      ],
      home: buildOnboarding(),
      ),
    );
  }
}
