import 'package:candle/data/services/wikipedia/wikipedia_client.dart';
import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Wikipedia articles in the language of the app; Wikipedias exist for both app languages.
class WikipediaRepository {
  WikipediaRepository({required this._client});

  final WikipediaClient _client;

  Future<Result<List<ArticleRef>>> nearby(LatLng position, {required String languageCode}) =>
      _client.nearby(position, languageCode: languageCode);

  Future<Result<ArticleSummary>> summary(ArticleRef article, {required String languageCode}) =>
      _client.summary(article.pageid, languageCode: languageCode);
}
