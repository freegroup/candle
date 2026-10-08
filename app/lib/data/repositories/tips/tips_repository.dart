import 'dart:convert';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/data/services/tips/tips_service.dart';
import 'package:candle/domain/models/tip.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';

/// The tips in the language of the app, and which ones the user has read.
/// Notifies listeners when the tips are loaded and when one is read.
///
/// The file format, for every language of the app:
/// `{"tips": [{"id": "...", "title": {"de": "...", "en": "..."}, "text": {"de": "...", "en": "..."}}]}`
class TipsRepository extends ChangeNotifier {
  TipsRepository({
    required TipsService tipsService,
    required SettingsRepository settingsRepository,
    required LanguageService languageService,
  })  : _service = tipsService,
        _settings = settingsRepository,
        _language = languageService {
    _language.addListener(notifyListeners);
  }

  /// A language a text is missing in falls back to this one.
  static const fallbackLanguage = 'en';

  final TipsService _service;
  final SettingsRepository _settings;
  final LanguageService _language;

  // The parsed file, null until loaded.
  List<Map<String, dynamic>>? _entries;

  /// The tips, in the order of the file.
  Future<Result<List<Tip>>> tips() async {
    try {
      _entries ??= _parse(await _service.bundledTips());
      return Result.ok([for (final entry in _entries!) _tipOf(entry)]);
    } on Exception catch (e) {
      return Result.error(e);
    } on TypeError catch (e) {
      // a file of another structure
      return Result.error(FormatException('Unexpected tips file: $e'));
    }
  }

  Future<void> markRead(String id) async {
    if (_settings.readTips.contains(id)) return;
    await _settings.markTipRead(id);
    notifyListeners();
  }

  static List<Map<String, dynamic>> _parse(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return (decoded['tips'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Tip _tipOf(Map<String, dynamic> entry) {
    final id = entry['id'] as String;
    return Tip(
      id: id,
      title: _inLanguage(entry['title']),
      text: _inLanguage(entry['text']),
      read: _settings.readTips.contains(id),
    );
  }

  String _inLanguage(Object? texts) {
    final byLanguage = (texts as Map<String, dynamic>).cast<String, String>();
    return byLanguage[_language.languageCode] ?? byLanguage[fallbackLanguage] ?? '';
  }

  @override
  void dispose() {
    _language.removeListener(notifyListeners);
    super.dispose();
  }
}
