import 'package:flutter/material.dart';

extension CustomThemeColors on ThemeData {
  Color get positiveColor => const Color.fromARGB(255, 41, 122, 44);
  Color get negativeColor => const Color.fromARGB(255, 192, 0, 0);
}

class CThemeData {
  static ThemeData get darkTheme {
    MaterialColor mySwatch = _createMaterialColor(Color.fromRGBO(255, 192, 4, 1));
    ThemeData baseTheme = ThemeData.dark(); // Use the default dark theme as base

    // Kopieren Sie das existierende TextTheme und ändern Sie nur das labelLarge-Attribut
    TextTheme customTextTheme = baseTheme.textTheme.copyWith(
      labelMedium: baseTheme.textTheme.labelLarge?.copyWith(
        fontSize: 14,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        fontSize: 16,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      cardColor: Color.fromRGBO(20, 20, 20, 1),
      dividerColor: Color.fromRGBO(60, 60, 60, 1),
      primaryColorDark: _createDarkerColor(mySwatch),
      textTheme: customTextTheme.apply(
        bodyColor: mySwatch,
        displayColor: mySwatch,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.fromRGBO(100, 100, 100, 1),
        labelStyle: TextStyle(color: mySwatch),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.black,
        titleTextStyle: TextStyle(
          color: mySwatch,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: mySwatch),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.black), // Transparent background
          side: MaterialStateProperty.all(BorderSide(color: Colors.black)), // Border Color
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0) // Adjust border radius as needed
              )),
          // Ensure that the button's minimum size is zero so it can be as small as its padding allows
          minimumSize: MaterialStateProperty.all(Size.zero),
          elevation: MaterialStateProperty.all(0.2),
          foregroundColor: MaterialStateProperty.all(mySwatch),
          padding:
              MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: mySwatch,
      ),
    );
  }

  static Color _createDarkerColor(MaterialColor color) {
    // Create a darker shade
    return color[900] ?? color.shade900; // Adjust the shade as needed
  }

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((r - ds < 0 ? 0 : (r - ds > 255 ? 255 : r - ds)).round()),
        g + ((g - ds < 0 ? 0 : (g - ds > 255 ? 255 : g - ds)).round()),
        b + ((b - ds < 0 ? 0 : (b - ds > 255 ? 255 : b - ds)).round()),
        1,
      );
    });
    return MaterialColor(color.value, swatch);
  }
}
