import 'dart:async';
import 'dart:io';
import 'package:candle/models/location_address.dart';
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
    String path = join(docDirector.path, "favorites_v5.db");
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
    formattedAddress TEXT,
    street TEXT,
    number TEXT,
    zip TEXT,
    city TEXT,
    country TEXT,
    lat REAL,
    lon REAL
  )
  ''');

    add(LocationAddress(
      lat: 49.45622156121109,
      lon: 8.596111485518252,
      name: "Lidl",
      city: "",
      country: "",
      number: "",
      street: "",
      zip: "",
      formattedAddress: "Irgendwo in Edingen",
    ));
  }

  Future<List<LocationAddress>> all() async {
    Database db = await instance.database;
    var rows = await db.query(_locationTable, orderBy: "name");
    List<LocationAddress> shopppingItems =
        rows.isNotEmpty ? rows.map((e) => LocationAddress.fromMap(e)).toList() : [];

    return shopppingItems;
  }

  Future<int> add(LocationAddress item) async {
    Database db = await instance.database;
    return await db.insert(_locationTable, item.toMap());
  }

  Future<int> remove(LocationAddress item) async {
    Database db = await instance.database;
    return await db.delete(_locationTable, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> update(LocationAddress item) async {
    Database db = await instance.database;
    return await db.update(_locationTable, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }
}
