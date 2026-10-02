import 'package:candle/ui/core/themes/candle_theme.dart';
import 'package:candle/ui/core/utils/colors.dart';
import 'package:flutter/material.dart';

extension CustomThemeColors on ThemeData {
  Color get positiveColor => const Color.fromARGB(255, 41, 122, 44);
  Color get negativeColor => const Color.fromARGB(255, 192, 0, 0);

  Color get _bg => scaffoldBackgroundColor;

  /// App-wide background gradient (see BackgroundWidget).
  List<Color> get backgroundGradient => [elevate(_bg, 0.14), elevate(_bg, 0.10)];

  /// Opaque backing of the DividedWidget panel.
  Color get panelColor => _bg;

  /// Gradient of the DividedWidget bottom content panel.
  List<Color> get panelGradient => [elevate(_bg, 0.008), elevate(_bg, 0.035)];

  /// Gradient of a home-screen tile; the second stop is [cardColor].
  List<Color> get tileGradient => [elevate(_bg, 0.04), cardColor];

  /// Gradient of a list row.
  List<Color> get rowGradient => [elevate(_bg, 0.047), elevate(_bg, 0.012)];
}

class CThemeData {
  /// Today's default look: gold on black (the first built-in profile).
  static ThemeData get darkTheme => theme(candleThemes.first);

  /// Builds the app theme from a colour [profile]. Backgrounds derive from
  /// [CandleTheme.bg], text and accents from [CandleTheme.tint], so switching
  /// the profile recolours the whole app.
  static ThemeData theme(CandleTheme profile) {
    final MaterialColor mySwatch = createMaterialColor(profile.tint);
    final Color bg = profile.bg;
    final ThemeData baseTheme = ThemeData.dark(); // base metrics; colours overridden below

    // Keep the two custom label sizes.
    final TextTheme customTextTheme = baseTheme.textTheme.copyWith(
      labelMedium: baseTheme.textTheme.labelLarge?.copyWith(fontSize: 14),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(fontSize: 16),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      cardColor: elevate(bg, 0.08),
      dividerColor: elevate(bg, 0.16),
      primaryColorDark: _createDarkerColor(mySwatch),
      textTheme: customTextTheme.apply(
        bodyColor: profile.tint,
        displayColor: profile.tint,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevate(bg, 0.39),
        labelStyle: TextStyle(color: profile.tint),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        shadowColor: bg,
        titleTextStyle: TextStyle(
          color: profile.tint,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: profile.tint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(bg),
          side: WidgetStateProperty.all(BorderSide(color: bg)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0))),
          minimumSize: WidgetStateProperty.all(Size.zero),
          elevation: WidgetStateProperty.all(0.2),
          foregroundColor: WidgetStateProperty.all(profile.tint),
          padding:
              WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: mySwatch,
      ),
    );
  }

  static Color _createDarkerColor(MaterialColor color) {
    return color[900] ?? color.shade900;
  }
}
