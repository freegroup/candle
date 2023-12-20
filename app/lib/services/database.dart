import 'dart:async';
import 'dart:io';
import 'package:candle/models/shopping_item.dart';
import "package:path/path.dart";

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // singleton Pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory docDirector = await getApplicationDocumentsDirectory();
    String path = join(docDirector.path, "shopping_items.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute(''' 
    CREATE TABLE shopping_items(
      id INTEGER PRIMARY KEY,
      name TEXT,
      done INTEGER
    )
    ''');
  }

  Future<List<ShoppingItem>> all() async {
    Database db = await instance.database;
    var rows = await db.query('shopping_items', orderBy: "name");
    List<ShoppingItem> shopppingItems =
        rows.isNotEmpty ? rows.map((e) => ShoppingItem.fromMap(e)).toList() : [];

    return shopppingItems;
  }

  Future<int> add(ShoppingItem item) async {
    Database db = await instance.database;
    return await db.insert('shopping_items', item.toMap());
  }

  Future<int> remove(ShoppingItem item) async {
    Database db = await instance.database;
    return await db.delete('shopping_items', where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> update(ShoppingItem item) async {
    Database db = await instance.database;
    return await db.update('shopping_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }
}
