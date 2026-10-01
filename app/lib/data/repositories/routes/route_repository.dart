import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';

/// Recorded walking routes with their points, ordered by name.
class RouteRepository {
  RouteRepository({required CandleDatabase database}) : _db = database;

  final CandleDatabase _db;

  Stream<List<Route>> watchAll() => _watch(() async {
        final rows =
            await (_db.select(_db.routes)..orderBy([(r) => OrderingTerm.asc(r.name)])).get();
        return Future.wait(rows.map(_withPoints));
      });

  Stream<Route?> watch(int id) => _watch(() async {
        final row =
            await (_db.select(_db.routes)..where((r) => r.id.equals(id))).getSingleOrNull();
        return row == null ? null : _withPoints(row);
      });

  /// Emits [read] now and again whenever a route or one of its points changes.
  Stream<T> _watch<T>(Future<T> Function() read) => _db
      .tableUpdates(TableUpdateQuery.onAllTables([_db.routes, _db.routePoints]))
      .map((_) => null)
      .startWith(null)
      .asyncMap((_) => read());

  /// Inserts a new route or replaces name, annotation and all points of the
  /// route with the same id; returns the id.
  Future<Result<int>> save(Route route) async {
    try {
      final id = await _db.transaction(() async {
        final inserted = await _db.into(_db.routes).insertOnConflictUpdate(RoutesCompanion.insert(
              id: route.id == null ? const Value.absent() : Value(route.id!),
              name: route.name,
              annotation: Value(route.annotation),
            ));
        final id = route.id ?? inserted; // SQLite reports no new row id for an update
        await (_db.delete(_db.routePoints)..where((p) => p.routeId.equals(id))).go();
        await _db.batch((batch) => batch.insertAll(_db.routePoints, [
              for (final (index, point) in route.points.indexed) _pointRow(id, index, point),
            ]));
        return id;
      });
      return Result.ok(id);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Appends one point to the end of a route, e.g. while recording.
  Future<Result<void>> addPoint(int routeId, NavigationPoint point) async {
    try {
      final count = _db.routePoints.id.count();
      final query = _db.selectOnly(_db.routePoints)
        ..addColumns([count])
        ..where(_db.routePoints.routeId.equals(routeId));
      final position = (await query.getSingle()).read(count)!;
      await _db.into(_db.routePoints).insert(_pointRow(routeId, position, point));
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await (_db.delete(_db.routes)..where((r) => r.id.equals(id))).go();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  RoutePointsCompanion _pointRow(int routeId, int position, NavigationPoint point) =>
      RoutePointsCompanion.insert(
        routeId: routeId,
        position: position,
        lat: point.coordinate.latitude,
        lon: point.coordinate.longitude,
        annotation: Value(point.annotation),
      );

  Future<Route> _withPoints(RouteRow row) async {
    final points = await (_db.select(_db.routePoints)
          ..where((p) => p.routeId.equals(row.id))
          ..orderBy([(p) => OrderingTerm.asc(p.position)]))
        .get();
    return Route(
      id: row.id,
      name: row.name,
      annotation: row.annotation,
      points: [
        for (final p in points)
          NavigationPoint(id: p.id, coordinate: LatLng(p.lat, p.lon), annotation: p.annotation),
      ],
    );
  }
}
