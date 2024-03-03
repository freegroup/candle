import 'package:candle/utils/colors.dart';
import 'package:flutter/material.dart';

extension CustomThemeColors on ThemeData {
  Color get positiveColor => const Color.fromARGB(255, 41, 122, 44);
  Color get negativeColor => const Color.fromARGB(255, 192, 0, 0);
}

class CThemeData {
  static ThemeData get darkTheme {
    MaterialColor mySwatch = createMaterialColor(const Color.fromRGBO(255, 192, 4, 1));
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
      cardColor: const Color.fromRGBO(20, 20, 20, 1),
      dividerColor: const Color.fromARGB(255, 40, 40, 40),
      primaryColorDark: _createDarkerColor(mySwatch),
      textTheme: customTextTheme.apply(
        bodyColor: mySwatch,
        displayColor: mySwatch,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color.fromRGBO(100, 100, 100, 1),
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
          side: MaterialStateProperty.all(const BorderSide(color: Colors.black)), // Border Color
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
}
