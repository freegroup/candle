import 'dart:async';
import 'dart:io';
import 'package:candle/models/location.dart';
import "package:path/path.dart";

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _locationTable = "location";

  // singleton Pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory docDirector = await getApplicationDocumentsDirectory();
    String path = join(docDirector.path, "favorites_v3.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute(''' 
    CREATE TABLE $_locationTable(
      id INTEGER PRIMARY KEY,
      name TEXT,
      lat REAL,
      lon REAL
    )
    ''');

    add(Location(lat: 49.45622156121109, lon: 8.596111485518252, name: "Lidl"));
  }

  Future<List<Location>> all() async {
    Database db = await instance.database;
    var rows = await db.query(_locationTable, orderBy: "name");
    List<Location> shopppingItems =
        rows.isNotEmpty ? rows.map((e) => Location.fromMap(e)).toList() : [];

    return shopppingItems;
  }

  Future<int> add(Location item) async {
    Database db = await instance.database;
    return await db.insert(_locationTable, item.toMap());
  }

  Future<int> remove(Location item) async {
    Database db = await instance.database;
    return await db.delete(_locationTable, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> update(Location item) async {
    Database db = await instance.database;
    return await db.update(_locationTable, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }
}
