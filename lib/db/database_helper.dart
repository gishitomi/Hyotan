// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/field_set.dart';
import '../models/field.dart';
import '../models/entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<void> init() async {
    _database = await _initDatabase();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'csv_data_app.db');
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
        field_set_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (field_set_id) REFERENCES field_sets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        field_set_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (field_set_id) REFERENCES field_sets (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertFieldSet(FieldSet fieldSet) async {
    final db = await database;
    return await db.insert('field_sets', fieldSet.toMap());
  }

  Future<List<FieldSet>> getFieldSets() async {
    final db = await database;
    final maps = await db.query('field_sets');
    return maps.map((map) => FieldSet.fromMap(map)).toList();
  }

  Future<int> insertField(Field field) async {
    final db = await database;
    return await db.insert('fields', field.toMap());
  }

  Future<List<Field>> getFields(int fieldSetId) async {
    final db = await database;
    final maps = await db.query(
      'fields',
      where: 'field_set_id = ?',
      whereArgs: [fieldSetId],
    );
    return maps.map((map) => Field.fromMap(map)).toList();
  }

  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    return await db.insert('entries', entry.toMap());
  }

  Future<List<Entry>> getEntries(int fieldSetId) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'field_set_id = ?',
      whereArgs: [fieldSetId],
    );
    return maps.map((map) => Entry.fromMap(map)).toList();
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

  Future<int> updateEntry(Entry entry) async {
    final db = await database;
    return await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFieldSet(int id) async {
    final db = await database;
    await db.delete('field_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteField(int id) async {
    final db = await database;
    return await db.delete('fields', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Field>> fetchFieldsBySetId(int fieldSetId) async {
    final db = await database;
    final maps = await db.query(
      'fields',
      where: 'field_set_id = ?',
      whereArgs: [fieldSetId],
    );
    return maps.map((map) => Field.fromMap(map)).toList();
  }

  Future<List<Entry>> fetchEntriesBySetId(int setId) async {
    final db = await database;
    final maps = await db.query(
      'data_entries',
      where: 'field_set_id = ?',
      whereArgs: [setId],
    );

    return maps.map((map) => Entry.fromMap(map)).toList();
  }
}
