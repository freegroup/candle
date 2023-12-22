import 'package:flutter/material.dart';

class CThemeData {
  static ThemeData get darkTheme {
    MaterialColor mySwatch = _createMaterialColor(Color.fromRGBO(255, 218, 0, 1));
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Color.fromRGBO(20, 20, 20, 1),
      cardColor: Colors.black,
      textTheme: TextTheme(
        bodySmall: TextStyle(color: mySwatch),
        bodyMedium: TextStyle(color: mySwatch),
        bodyLarge: TextStyle(color: mySwatch),
        titleSmall: TextStyle(color: mySwatch),
        titleMedium: TextStyle(color: mySwatch),
        titleLarge: TextStyle(color: mySwatch),
        displaySmall: TextStyle(color: mySwatch),
        displayMedium: TextStyle(color: mySwatch),
        displayLarge: TextStyle(color: mySwatch),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color.fromRGBO(100, 100, 100, 1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.black,
        titleTextStyle: TextStyle(
          color: mySwatch,
          letterSpacing: 5,
          fontSize: 30,
          fontWeight: FontWeight.w300,
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
