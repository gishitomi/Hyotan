// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'csv_entry_screen.dart';
import 'csv_list_screen.dart';
import 'field_edit_screen.dart';
import '../models/field.dart';
import '../models/field_set.dart';
import '../db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FieldSet> fieldSets = [];

  @override
  void initState() {
    super.initState();
    // _loadFieldSets();
  }

  Future<void> _loadFieldSets() async {
    try {
      final sets = await DatabaseHelper.instance.getFieldSets();
      setState(() => fieldSets = sets);
    } catch (e, st) {
      print('DB読み込みエラー: $e');
      print(st);
    }
  }

  void _openFieldSet(FieldSet fieldSet) async {
    final fields = await DatabaseHelper.instance.fetchFieldsBySetId(
      fieldSet.id!,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CsvEntryScreen(fields: fields)),
    );
  }

  void _editFields(FieldSet fieldSet) async {
    final fields = await DatabaseHelper.instance.fetchFieldsBySetId(
      fieldSet.id!,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FieldEditScreen(
              fields: fields,
              onSave: (updatedFields) async {
                for (final field in updatedFields) {
                  if (field.id == null) {
                    await DatabaseHelper.instance.insertField(
                      field.copyWith(fieldSetId: fieldSet.id),
                    );
                  } else {
                    await DatabaseHelper.instance.updateField(field);
                  }
                }
                _loadFieldSets();
              },
            ),
      ),
    );
  }

  void _createFieldSet() async {
    final newSet = FieldSet(name: '新しいセット');
    final id = await DatabaseHelper.instance.insertFieldSet(newSet);
    await _loadFieldSets();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('セットを作成しました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CSVデータ収集アプリ')),
      body: const Center(child: Text('テスト用')), // 仮の表示
    );
  }
}
