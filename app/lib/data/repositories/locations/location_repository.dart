import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/drift.dart';

/// The places the user saved, ordered by name.
class LocationRepository {
  LocationRepository({required CandleDatabase database}) : _db = database;

  final CandleDatabase _db;

  Stream<List<LocationAddress>> watchAll() =>
      (_db.select(_db.locations)..orderBy([(l) => OrderingTerm.asc(l.name)]))
          .watch()
          .map((rows) => rows.map(_toModel).toList());

  /// Inserts a new place or updates the one with the same id; returns the id.
  Future<Result<int>> save(LocationAddress location) async {
    try {
      final row = LocationsCompanion.insert(
        id: location.id == null ? const Value.absent() : Value(location.id!),
        name: location.name,
        formattedAddress: Value(location.formattedAddress),
        street: Value(location.street),
        number: Value(location.number),
        zip: Value(location.zip),
        city: Value(location.city),
        country: Value(location.country),
        lat: location.lat,
        lon: location.lon,
      );
      final inserted = await _db.into(_db.locations).insertOnConflictUpdate(row);
      // SQLite reports no new row id for an update.
      return Result.ok(location.id ?? inserted);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await (_db.delete(_db.locations)..where((l) => l.id.equals(id))).go();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static LocationAddress _toModel(LocationRow row) => LocationAddress(
        id: row.id,
        name: row.name,
        formattedAddress: row.formattedAddress,
        street: row.street,
        number: row.number,
        zip: row.zip,
        city: row.city,
        country: row.country,
        lat: row.lat,
        lon: row.lon,
      );
}
