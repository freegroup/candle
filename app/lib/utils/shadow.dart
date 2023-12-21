import 'package:flutter/material.dart';

List<BoxShadow> createShadow() {
  return const [
    BoxShadow(
      color: Colors.black, // Use yellow for debugging, change to Colors.black for production
      blurRadius: 4.0, // Adjust the blur radius
      offset: Offset(2.0, 2.0), // Adjust the offset
    ),
  ];
}
