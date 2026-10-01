import 'dart:async';

import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Records the walked route; lives as long as the app, so leaving the
/// recording screen does not stop the recording.
class RecordingRepository extends ChangeNotifier {
  RecordingRepository({
    required RouteRepository routeRepository,
    required LocationService locationService,
    this.onPointRecorded,
  })  : _routes = routeRepository,
        _location = locationService;

  final RouteRepository _routes;
  final LocationService _location;

  /// Called for every recorded point, e.g. a short vibration as a sign of life.
  final void Function()? onPointRecorded;

  int? _routeId;
  StreamSubscription<void>? _positions;

  /// The route being recorded, or null when nothing is recorded.
  int? get routeId => _routeId;
  bool get isRecording => _routeId != null;

  /// Starts recording into the route [name]; an existing route of that name is
  /// recorded anew. [notificationTitle] and [notificationText] are shown on Android
  /// while the recording runs.
  Future<Result<int>> start(
    String name, {
    required String notificationTitle,
    required String notificationText,
  }) async {
    if (isRecording) return Result.error(Exception('Already recording'));

    final existing = (await _routes.watchAll().first).where((r) => r.name == name).firstOrNull;
    final saved = await _routes.save(existing?.copyWith(points: []) ?? Route(name: name, points: []));
    if (saved is! Ok<int>) return saved;

    final routeId = saved.value;
    _routeId = routeId;
    _positions = _location
        .backgroundPositions(title: notificationTitle, text: notificationText)
        .asyncMap((position) async {
      final result =
          await _routes.addPoint(routeId, NavigationPoint(coordinate: position, annotation: ''));
      if (result case Error(:final error)) _log.w('Recording a point failed: $error');
      onPointRecorded?.call();
    }).listen(null, onError: (Object e) => _log.w('Position stream error: $e'));
    notifyListeners();
    return saved;
  }

  /// Ends the recording; the route is kept only if [save] is true.
  Future<Result<void>> stop({required bool save}) async {
    final routeId = _routeId;
    if (routeId == null) return const Result.ok(null);

    await _positions?.cancel();
    _positions = null;
    _routeId = null;
    notifyListeners();
    return save ? const Result.ok(null) : _routes.delete(routeId);
  }

  @override
  void dispose() {
    unawaited(_positions?.cancel());
    super.dispose();
  }
}
