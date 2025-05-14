// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/field_set.dart';
import '../models/field.dart';
import '../models/entry.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'csv_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE field_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fieldSetId INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY(fieldSetId) REFERENCES field_sets(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fieldSetId INTEGER NOT NULL,
        values TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(fieldSetId) REFERENCES field_sets(id) ON DELETE CASCADE
      )
    ''');
  }

  // FieldSet CRUD
  Future<int> insertFieldSet(FieldSet fieldSet) async {
    final db = await database;
    return await db.insert('field_sets', fieldSet.toMap());
  }

  Future<List<FieldSet>> getFieldSets() async {
    final db = await database;
    final maps = await db.query('field_sets');
    return maps.map((m) => FieldSet.fromMap(m)).toList();
  }

  Future<int> updateFieldSet(FieldSet fieldSet) async {
    final db = await database;
    return await db.update(
      'field_sets',
      fieldSet.toMap(),
      where: 'id = ?',
      whereArgs: [fieldSet.id],
    );
  }

  Future<int> deleteFieldSet(int id) async {
    final db = await database;
    return await db.delete('field_sets', where: 'id = ?', whereArgs: [id]);
  }

  // Field CRUD
  Future<int> insertField(Field field) async {
    final db = await database;
    return await db.insert('fields', field.toMap());
  }

  Future<List<Field>> getFields(int fieldSetId) async {
    final db = await database;
    final maps = await db.query(
      'fields',
      where: 'fieldSetId = ?',
      whereArgs: [fieldSetId],
    );
    return maps.map((m) => Field.fromMap(m)).toList();
  }

  Future<int> updateField(Field field) async {
    final db = await database;
    return await db.update(
      'fields',
      field.toMap(),
      where: 'id = ?',
      whereArgs: [field.id],
    );
  }

  Future<int> deleteField(int id) async {
    final db = await database;
    return await db.delete('fields', where: 'id = ?', whereArgs: [id]);
  }

  // Entry CRUD
  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    final map = entry.toMap();
    map['values'] = jsonEncode(entry.values); // JSON文字列で保存
    return await db.insert('entries', map);
  }

  Future<List<Entry>> getEntries(int fieldSetId) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'fieldSetId = ?',
      whereArgs: [fieldSetId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) {
      m['values'] = jsonDecode(m['values'] as String);
      return Entry.fromMap(m);
    }).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}
