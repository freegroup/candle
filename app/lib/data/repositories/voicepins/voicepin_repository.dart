import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/voicepin.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/drift.dart';

/// Spoken notes the user left at a position, newest first.
class VoicePinRepository {
  VoicePinRepository({required CandleDatabase database}) : _db = database;

  final CandleDatabase _db;

  Stream<List<VoicePin>> watchAll() =>
      (_db.select(_db.voicePins)..orderBy([(v) => OrderingTerm.desc(v.created)]))
          .watch()
          .map((rows) => rows.map(_toModel).toList());

  /// Inserts a new voice pin or updates the one with the same id; returns the id.
  Future<Result<int>> save(VoicePin pin) async {
    try {
      final row = VoicePinsCompanion.insert(
        id: pin.id == null ? const Value.absent() : Value(pin.id!),
        name: pin.name,
        memo: Value(pin.memo),
        lat: pin.lat,
        lon: pin.lon,
        created: pin.created == null ? const Value.absent() : Value(pin.created!),
      );
      final inserted = await _db.into(_db.voicePins).insertOnConflictUpdate(row);
      // SQLite reports no new row id for an update.
      return Result.ok(pin.id ?? inserted);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await (_db.delete(_db.voicePins)..where((v) => v.id.equals(id))).go();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static VoicePin _toModel(VoicePinRow row) => VoicePin(
        id: row.id,
        name: row.name,
        memo: row.memo,
        lat: row.lat,
        lon: row.lon,
        created: row.created,
      );
}
