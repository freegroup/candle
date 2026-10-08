import 'package:candle/data/services/tips/tips_service.dart';

/// Tips from a string instead of the asset; [json] null fails like a missing file.
class FakeTipsService implements TipsService {
  FakeTipsService([this.json = sampleTips]);

  String? json;

  static const sampleTips = '''
{"tips": [
  {"id": "notes", "title": {"de": "Was sind Ortsnotizen?", "en": "What are location notes?"},
   "text": {"de": "Ein Hinweis.\\n\\nKommst du vorbei, vibriert es.", "en": "A hint.\\n\\nWhen you pass, it vibrates."}},
  {"id": "radar", "title": {"en": "The radar"}, "text": {"en": "Point the phone."}}
]}''';

  @override
  Future<String> bundledTips() async {
    final value = json;
    if (value == null) throw Exception('no tips file');
    return value;
  }
}
