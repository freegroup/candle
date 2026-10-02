import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'candle_database.g.dart';

/// Saved places of the user.
@DataClassName('LocationRow')
class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get formattedAddress => text().withDefault(const Constant(''))();
  TextColumn get street => text().withDefault(const Constant(''))();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get zip => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get country => text().withDefault(const Constant(''))();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
}

/// Notes bound to a position, read out when the user gets there.
@DataClassName('LocationNoteRow')
class LocationNotes extends Table {
  // the name of the first version ("voice pins"); renaming it would hide the
  // notes saved with that version
  @override
  String get tableName => 'voice_pins';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get memo => text().withDefault(const Constant(''))();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  DateTimeColumn get created => dateTime().withDefault(currentDateAndTime)();
}

/// Recorded walking routes; the points live in [RoutePoints].
@DataClassName('RouteRow')
class Routes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get annotation => text().withDefault(const Constant(''))();
  DateTimeColumn get created => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('RoutePointRow')
class RoutePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routeId => integer().references(Routes, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get annotation => text().withDefault(const Constant(''))();
}

@DriftDatabase(tables: [Locations, LocationNotes, Routes, RoutePoints])
class CandleDatabase extends _$CandleDatabase {
  CandleDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
      );

  static QueryExecutor _open() => driftDatabase(name: 'candle');
}
