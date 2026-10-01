import 'package:candle/data/repositories/wikipedia/wikipedia_repository.dart';
import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/ui/wikipedia/view_models/wikipedia_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_location_service.dart';

ArticleRef _article(String title, double lat) =>
    ArticleRef(pageid: title.length, ns: 0, title: title, lat: lat, lon: 8, dist: 0, primary: '');

class _FakeWikipedia implements WikipediaRepository {
  Result<List<ArticleRef>> nearbyResult = Result.ok([_article('far', 1.1), _article('near', 1.01)]);
  final requests = <(LatLng, String)>[];

  @override
  Future<Result<List<ArticleRef>>> nearby(LatLng position, {required String languageCode}) async {
    requests.add((position, languageCode));
    return nearbyResult;
  }

  @override
  Future<Result<ArticleSummary>> summary(ArticleRef article, {required String languageCode}) async =>
      Result.ok(ArticleSummary(pageid: article.pageid, title: article.title, extract: 'text'));
}

void main() {
  late _FakeWikipedia wikipedia;
  late FakeLocationService location;

  setUp(() {
    wikipedia = _FakeWikipedia();
    location = FakeLocationService(const Result.ok(LatLng(1, 8)));
  });

  WikipediaViewModel create() =>
      WikipediaViewModel(wikipediaRepository: wikipedia, locationService: location, languageCode: 'en');

  test('loads the articles in the app language, nearest first', () async {
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.articles.map((a) => a.title), ['near', 'far']);
    expect(wikipedia.requests.single.$2, 'en');
    viewModel.dispose();
  });

  test('re-sorts while walking and reloads only after 500 m', () async {
    final viewModel = create();
    await pumpEventQueue();

    location.controller.add(const LatLng(1.003, 8)); // ~330 m
    await pumpEventQueue();
    expect(wikipedia.requests, hasLength(1));

    location.controller.add(const LatLng(1.1, 8));
    await pumpEventQueue();
    expect(viewModel.articles.map((a) => a.title), ['far', 'near']);
    expect(wikipedia.requests, hasLength(2));
    viewModel.dispose();
  });

  test('reports a failed load so the screen can offer a retry', () async {
    wikipedia.nearbyResult = Result.error(Exception('offline'));
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.load.error, isTrue);
    viewModel.dispose();
  });
}
