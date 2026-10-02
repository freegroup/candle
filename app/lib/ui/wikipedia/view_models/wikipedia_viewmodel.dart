import 'dart:async';

import 'package:candle/data/repositories/wikipedia/wikipedia_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Wikipedia articles around the user, nearest first while the user walks.
class WikipediaViewModel extends ChangeNotifier {
  WikipediaViewModel({
    required WikipediaRepository wikipediaRepository,
    required LocationService locationService,
    this.reloadDistanceInMeter = 500,
  })  : _wikipedia = wikipediaRepository,
        _location = locationService {
    load = Command0(_load)..execute();
    summary = Command1(_summary);
  }

  final WikipediaRepository _wikipedia;
  final LocationService _location;
  final int reloadDistanceInMeter;

  late final Command0<void> load;

  /// The text of an article, to read it out or show it.
  late final Command1<ArticleSummary, ArticleRef> summary;

  List<ArticleRef> _articles = [];
  List<ArticleRef> get articles => _articles;

  LatLng? _position;
  LatLng? get position => _position;

  LatLng? _loadedAt;
  StreamSubscription<LatLng>? _positions;

  int distanceTo(ArticleRef article) =>
      _position == null ? 0 : calculateDistance(article.latlng(), _position!).round();

  Future<Result<void>> _load() async {
    final position = _position ??
        switch (await _location.currentPosition()) {
          Ok(:final value) => value,
          Error() => null,
        };
    if (position == null) return Result.error(Exception('No GPS position available'));
    _position = position;

    final result = await _wikipedia.nearby(position);
    switch (result) {
      case Ok(:final value):
        _articles = value;
        _loadedAt = position;
        _sort();
        _positions ??= _location.positions().listen(
              _onPosition,
              onError: (Object e) => _log.w('Position stream error: $e'),
            );
        return const Result.ok(null);
      case Error(:final error):
        _log.w('Loading Wikipedia articles failed: $error');
        return Result.error(error);
    }
  }

  Future<Result<ArticleSummary>> _summary(ArticleRef article) =>
      _wikipedia.summary(article);

  void _onPosition(LatLng position) {
    _position = position;
    _sort();
    final loadedAt = _loadedAt;
    if (loadedAt != null &&
        !load.running &&
        calculateDistance(loadedAt, position) > reloadDistanceInMeter) {
      unawaited(load.execute());
    }
  }

  void _sort() {
    _articles = [..._articles]..sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_positions?.cancel());
    load.dispose();
    summary.dispose();
    super.dispose();
  }
}
