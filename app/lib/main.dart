import 'package:candle/app.dart';
import 'package:candle/services/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => GeoServiceProvider())],
    child: const CandleApp(),
  ));
}
