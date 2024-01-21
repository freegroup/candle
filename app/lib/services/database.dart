import 'dart:async';
import 'dart:io';
import 'package:candle/models/location_address.dart';
import 'package:candle/models/route.dart';
import 'package:candle/models/voicepin.dart';
import "package:path/path.dart";

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _locationTable = "location";
  static const String _voicepinTable = "voicepin";
  static const String _routeTable = "route";

  // singleton Pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory docDirector = await getApplicationDocumentsDirectory();
    String path = join(docDirector.path, "storage_v1.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute(''' 
    CREATE TABLE $_voicepinTable(
      id INTEGER PRIMARY KEY,
      name TEXT,
      memo TEXT,
      lat REAL,
      lon REAL,
      created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');

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

    // Create route table with a text field for route points
    await db.execute(''' 
    CREATE TABLE $_routeTable(
      id INTEGER PRIMARY KEY,
      name TEXT,
      annotation TEXT,
      points TEXT,
      created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');
  }

  Future<List<LocationAddress>> allLocations() async {
    Database db = await instance.database;
    var rows = await db.query(_locationTable, orderBy: "name");
    return rows.isNotEmpty ? rows.map((e) => LocationAddress.fromMap(e)).toList() : [];
  }

  Future<int> addLocation(LocationAddress item) async {
    Database db = await instance.database;
    return db.insert(_locationTable, item.toMap());
  }

  Future<int> removeLocation(LocationAddress item) async {
    Database db = await instance.database;
    return db.delete(_locationTable, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> updateLocation(LocationAddress item) async {
    Database db = await instance.database;
    return db.update(_locationTable, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<List<VoicePin>> allVoicePins() async {
    Database db = await instance.database;
    var rows = await db.query(_voicepinTable);
    return rows.isNotEmpty ? rows.map((e) => VoicePin.fromMap(e)).toList() : [];
  }

  Future<int> addVoicePin(VoicePin item) async {
    Database db = await instance.database;
    return db.insert(_voicepinTable, item.toMap());
  }

  Future<int> removeVoicePin(VoicePin item) async {
    Database db = await instance.database;
    return db.delete(_voicepinTable, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> updateVoicePin(VoicePin item) async {
    Database db = await instance.database;
    return db.update(_voicepinTable, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<List<Route>> allRoutes() async {
    Database db = await instance.database;
    var rows = await db.query(_routeTable, orderBy: "name");
    return rows.isNotEmpty
        ? rows.map((e) {
            String pointsJson = e['points'] as String;
            var route = Route.fromMap(e);
            route.points = Route.pointsFromJson(pointsJson);
            return route;
          }).toList()
        : [];
  }

  Future<List<Route>> allRoutesExcept(String excludedRouteName) async {
    Database db = await instance.database;
    var rows = await db.query(
      _routeTable,
      where: 'name != ?',
      whereArgs: [excludedRouteName],
      orderBy: "name",
    );
    return rows.isNotEmpty
        ? rows.map((e) {
            String pointsJson = e['points'] as String;
            var route = Route.fromMap(e);
            route.points = Route.pointsFromJson(pointsJson); // Convert JSON string back to points
            return route;
          }).toList()
        : [];
  }

  // Create (Add) operation for Route
  Future<int> addRoute(Route route) async {
    Database db = await instance.database;
    var routeMap = route.toMap();
    routeMap['points'] = route.pointsToJson();
    return db.insert(_routeTable, routeMap);
  }

  // Read (Get) operation for Route
  Future<Route?> getRouteById(int id) async {
    Database db = await instance.database;
    var maps = await db.query(_routeTable, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      var route = Route.fromMap(maps.first);

      // Explicitly cast the points field to String
      String pointsJson = maps.first['points'] as String;
      route.points = Route.pointsFromJson(pointsJson); // Convert JSON string back to points

      return route;
    }
    return null;
  }

  // Read (Get) operation for Route by name
  Future<Route?> getRouteByName(String name) async {
    Database db = await instance.database;
    var maps = await db.query(_routeTable, where: 'name = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      var route = Route.fromMap(maps.first);

      // Explicitly cast the points field to String
      String pointsJson = maps.first['points'] as String;
      route.points = Route.pointsFromJson(pointsJson); // Convert JSON string back to points

      return route;
    }
    return null;
  }

  // Update operation for Route
  Future<int> updateRoute(Route route) async {
    Database db = await instance.database;
    var routeMap = route.toMap();
    routeMap['points'] = route.pointsToJson(); // Convert points to JSON string
    return db.update(_routeTable, routeMap, where: 'id = ?', whereArgs: [route.id]);
  }

  // Delete operation for Route
  Future<int> removeRoute(Route route) async {
    Database db = await instance.database;
    return db.delete(_routeTable, where: 'id = ?', whereArgs: [route.id]);
  }
}
