import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/data/services/wikipedia/wikipedia_client.dart';
import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Wikipedia articles in the language of the app; Wikipedias exist for both app languages.
class WikipediaRepository {
  WikipediaRepository({required this._client, required this._language});

  final WikipediaClient _client;
  final LanguageService _language;

  Future<Result<List<ArticleRef>>> nearby(LatLng position) =>
      _client.nearby(position, languageCode: _language.languageCode);

  Future<Result<ArticleSummary>> summary(ArticleRef article) =>
      _client.summary(article.pageid, languageCode: _language.languageCode);
}
