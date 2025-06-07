// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/field_set.dart';
import '../models/field.dart';
import '../models/entry.dart';
import 'dart:convert';
import 'dart:io';

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
    print('initDb start');
    // プロジェクト配下の .dart_tool/sqflite_common_ffi/databases/csv_app.db に保存
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'csv_app.db');
    print('DB path: $path');
    final db = await openDatabase(path, version: 1, onCreate: _onCreate);
    print('DB opened');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    print('onCreate start');
    await db.execute('''
      CREATE TABLE field_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    print('field_sets created');
    await db.execute('''
      CREATE TABLE fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fieldSetId INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY(fieldSetId) REFERENCES field_sets(id) ON DELETE CASCADE
      )
    ''');
    print('fields created');
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fieldSetId INTEGER NOT NULL,
        entry_values TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(fieldSetId) REFERENCES field_sets(id) ON DELETE CASCADE
      )
    ''');
    print('entries created');
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

  Future<void> updateFieldSet(FieldSet fieldSet) async {
    final db = await database;
    await db.update(
      'field_sets',
      {'name': fieldSet.name},
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

  Future<void> deleteFieldsBySetId(int fieldSetId) async {
    final db = await database;
    await db.delete(
      'fields',
      where: 'fieldSetId = ?',
      whereArgs: [fieldSetId],
    );
  }

  // Entry CRUD
  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    final map = entry.toMap();
    map['entry_values'] = jsonEncode(entry.values); // JSON文字列で保存
    map.remove('values'); // ← 追加: Map型のままのvaluesを削除
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
      final map = Map<String, dynamic>.from(m); // クローンを作成
      map['values'] = jsonDecode(map['entry_values'] as String);
      return Entry.fromMap(map);
    }).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertTestData() async {
    // FieldSet追加
    final setId = await insertFieldSet(FieldSet(name: 'テストセット'));
    // Field追加
    await insertField(Field(fieldSetId: setId, name: '項目1', type: 'text'));
    await insertField(Field(fieldSetId: setId, name: '項目2', type: 'text'));
    // Entry追加
    await insertEntry(Entry(
      fieldSetId: setId,
      values: {'項目1': 'サンプルA', '項目2': 'サンプルB'},
      createdAt: DateTime.now(),
    ));
  }

  Future<void> renameEntryField(
      int fieldSetId, String oldName, String newName) async {
    final db = await database;
    final entries = await db.query(
      'entries',
      where: 'fieldSetId = ?',
      whereArgs: [fieldSetId],
    );
    for (final entry in entries) {
      final values = Map<String, dynamic>.from(
          jsonDecode(entry['entry_values'] as String));
      if (values.containsKey(oldName)) {
        values[newName] = values.remove(oldName);
        await db.update(
          'entries',
          {'entry_values': jsonEncode(values)},
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    }
  }

  Future<void> removeEntryField(int fieldSetId, String fieldName) async {
    final db = await database;
    final entries = await db.query(
      'entries',
      where: 'fieldSetId = ?',
      whereArgs: [fieldSetId],
    );
    for (final entry in entries) {
      final values = Map<String, dynamic>.from(
          jsonDecode(entry['entry_values'] as String));
      if (values.containsKey(fieldName)) {
        values.remove(fieldName);
        await db.update(
          'entries',
          {'entry_values': jsonEncode(values)}, // ← 修正
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    }
  }

  Future<List<String>> getFieldTypes(int fieldSetId) async {
    final db = await database;
    final List<Map<String, dynamic>> fields = await db.query(
      'fields',
      where: 'fieldSetId = ?',
      whereArgs: [fieldSetId],
    );
    return fields.map((field) => field['type'] as String).toList();
  }

  Future<void> updateEntry(Entry entry) async {
    final db = await database;
    await db.update(
      'entries',
      {
        'fieldSetId': entry.fieldSetId,
        'entry_values': jsonEncode(entry.values),
        'createdAt': entry.createdAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }
}
