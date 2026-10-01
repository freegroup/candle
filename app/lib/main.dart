import 'package:candle/app.dart';
import 'package:candle/config/dependencies.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await SettingsRepository.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider.value(value: settings), ...providers],
    child: const CandleApp(),
  ));
}
