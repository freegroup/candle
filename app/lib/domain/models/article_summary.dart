import 'package:candle/utils/parse_html.dart';

/// Title and introduction of a Wikipedia article as plain text.
class ArticleSummary {
  const ArticleSummary({required this.pageid, required this.title, required this.extract});

  factory ArticleSummary.fromJson(Map<String, dynamic> json) => ArticleSummary(
        pageid: json['pageid'] as int,
        title: json['title'] as String? ?? '',
        extract: Html.toPlainText(json['extract'] as String? ?? ''),
      );

  final int pageid;
  final String title;
  final String extract;
}
