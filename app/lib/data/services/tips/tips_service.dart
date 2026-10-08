import 'package:flutter/services.dart';

/// The tips that come with the app: assets/tips/tips.json, in all app languages.
/// Later the Candle server can add more in the same format.
class TipsService {
  TipsService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// The content of the tips file.
  Future<String> bundledTips() => _bundle.loadString('assets/tips/tips.json');
}
