import 'package:flutter/material.dart';

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDarkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDarkened.toColor();
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((r - ds < 0 ? 0 : (r - ds > 255 ? 255 : r - ds)).round()),
      g + ((g - ds < 0 ? 0 : (g - ds > 255 ? 255 : g - ds)).round()),
      b + ((b - ds < 0 ? 0 : (b - ds > 255 ? 255 : b - ds)).round()),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
