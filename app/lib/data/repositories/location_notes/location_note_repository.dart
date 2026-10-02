import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/drift.dart';

/// Spoken notes the user left at a position, newest first.
class LocationNoteRepository {
  LocationNoteRepository({required CandleDatabase database}) : _db = database;

  final CandleDatabase _db;

  Stream<List<LocationNote>> watchAll() =>
      (_db.select(_db.locationNotes)..orderBy([(v) => OrderingTerm.desc(v.created)]))
          .watch()
          .map((rows) => rows.map(_toModel).toList());

  /// Inserts a new voice pin or updates the one with the same id; returns the id.
  Future<Result<int>> save(LocationNote pin) async {
    try {
      final row = LocationNotesCompanion.insert(
        id: pin.id == null ? const Value.absent() : Value(pin.id!),
        name: pin.name,
        memo: Value(pin.memo),
        lat: pin.lat,
        lon: pin.lon,
        created: pin.created == null ? const Value.absent() : Value(pin.created!),
      );
      final inserted = await _db.into(_db.locationNotes).insertOnConflictUpdate(row);
      // SQLite reports no new row id for an update.
      return Result.ok(pin.id ?? inserted);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await (_db.delete(_db.locationNotes)..where((v) => v.id.equals(id))).go();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static LocationNote _toModel(LocationNoteRow row) => LocationNote(
        id: row.id,
        name: row.name,
        memo: row.memo,
        lat: row.lat,
        lon: row.lon,
        created: row.created,
      );
}
