import 'dart:convert';

import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/config/app_config.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Wikipedia articles near a position (MediaWiki GeoData API) and their summaries.
class WikipediaClient {
  WikipediaClient({required this._client});

  final http.Client _client;

  Future<Result<List<ArticleRef>>> nearby(
    LatLng position, {
    required String languageCode,
    int radiusInMeter = 10000,
    int limit = 40,
  }) async {
    final json = await _query(languageCode, {
      'list': 'geosearch',
      'gsprop': 'type',
      'gsradius': '$radiusInMeter',
      'gslimit': '$limit',
      'gscoord': '${position.latitude}|${position.longitude}',
    });
    return switch (json) {
      Ok(:final value) => Result.ok([
          for (final article in (value['geosearch'] as List).cast<Map<String, dynamic>>())
            ArticleRef.fromJson(article),
        ]),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<ArticleSummary>> summary(int pageId, {required String languageCode}) async {
    final json = await _query(languageCode, {'pageids': '$pageId', 'prop': 'extracts'});
    return switch (json) {
      Ok(:final value) => Result.ok(ArticleSummary.fromJson(
          (value['pages'] as Map<String, dynamic>)['$pageId'] as Map<String, dynamic>)),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<Map<String, dynamic>>> _query(String languageCode, Map<String, String> params) async {
    try {
      final response = await _client.get(
        Uri.https('$languageCode.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'format': 'json',
          'uselang': languageCode,
          ...params,
        }),
        headers: HttpConfig.headers,
      );
      if (response.statusCode != 200) {
        return Result.error(http.ClientException('Wikipedia ${response.statusCode}'));
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return Result.ok(json['query'] as Map<String, dynamic>);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
