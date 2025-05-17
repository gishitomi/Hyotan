// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'csv_entry_screen.dart';
import 'csv_list_screen.dart';
import 'field_edit_screen.dart';
import '../db/database_helper.dart';
import '../models/field_set.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<FieldSet>> _fieldSetsFuture;

  @override
  void initState() {
    super.initState();
    _fieldSetsFuture = DatabaseHelper.instance.getFieldSets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSVデータ収集アプリ'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box),
            tooltip: 'テストデータ追加',
            onPressed: () async {
              await DatabaseHelper.instance.insertTestData();
              setState(() {
                _fieldSetsFuture = DatabaseHelper.instance.getFieldSets();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('テストデータを追加しました')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<FieldSet>>(
        future: _fieldSetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          final fieldSets = snapshot.data!;
          if (fieldSets.isEmpty) {
            return Center(child: Text('セットがありません'));
          }
          return ListView(
            children: [
              ListTile(
                leading: Icon(Icons.add),
                title: Text('新しいセット'),
                onTap: () {
                  // 項目編集画面へ遷移（新規作成用）
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FieldEditScreen(
                        setName: '新しいセット',
                        fields: [],
                      ),
                    ),
                  );
                },
              ),
              Divider(),
              ...fieldSets.map(
                (fs) => ListTile(
                  title: Text(fs.name),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      // DBからfieldsを取得
                      final fields =
                          await DatabaseHelper.instance.getFields(fs.id!);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FieldEditScreen(
                            setName: fs.name,
                            fieldSetId: fs.id,
                            fields: fields.map((f) => f.name).toList(),
                          ),
                        ),
                      );
                      setState(() {
                        _fieldSetsFuture =
                            DatabaseHelper.instance.getFieldSets();
                      });
                    },
                  ),
                  onTap: () async {
                    // DBからfieldsを取得
                    final fields =
                        await DatabaseHelper.instance.getFields(fs.id!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CsvEntryScreen(
                          setName: fs.name,
                          fieldSetId: fs.id!,
                          fields: fields.map((f) => f.name).toList(),
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CsvListScreen(
                          setName: fs.name,
                          fieldSetId: fs.id!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
