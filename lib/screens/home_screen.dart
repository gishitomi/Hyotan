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
                onTap: () async {
                  // セット名入力ダイアログを表示
                  final controller = TextEditingController();
                  final setName = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('新しいセット名を入力'),
                      content: TextField(
                        controller: controller,
                        decoration: InputDecoration(labelText: 'セット名'),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                  if (setName != null && setName.isNotEmpty) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FieldEditScreen(
                          setName: setName,
                          fields: [],
                        ),
                      ),
                    );
                    // ★ ここで再取得
                    if (result == true) {
                      setState(() {
                        _fieldSetsFuture =
                            DatabaseHelper.instance.getFieldSets();
                      });
                    }
                  }
                },
              ),
              Divider(),
              ...fieldSets.map(
                (fs) => ListTile(
                  title: Text(fs.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // セット名編集ボタン
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'セット名編集',
                        onPressed: () async {
                          final controller =
                              TextEditingController(text: fs.name);
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('セット名を編集'),
                              content: TextField(
                                controller: controller,
                                decoration: InputDecoration(labelText: 'セット名'),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                      context, controller.text.trim()),
                                  child: Text('保存'),
                                ),
                              ],
                            ),
                          );
                          if (newName != null &&
                              newName.isNotEmpty &&
                              newName != fs.name) {
                            // DBを更新
                            await DatabaseHelper.instance.updateFieldSet(
                              fs.copyWith(name: newName),
                            );
                            setState(() {
                              _fieldSetsFuture =
                                  DatabaseHelper.instance.getFieldSets();
                            });
                          }
                        },
                      ),
                      // 項目編集ボタン
                      IconButton(
                        icon: Icon(Icons.view_column, color: Colors.green),
                        tooltip: '項目編集',
                        onPressed: () async {
                          // DBから項目リストを取得
                          final fields =
                              await DatabaseHelper.instance.getFields(fs.id!);
                          final fieldNames = fields.map((f) => f.name).toList();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FieldEditScreen(
                                setName: fs.name,
                                fieldSetId: fs.id,
                                fields: fieldNames,
                              ),
                            ),
                          );
                          setState(() {
                            _fieldSetsFuture =
                                DatabaseHelper.instance.getFieldSets();
                          });
                        },
                      ),
                      // セット削除ボタン
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'セット削除',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('削除確認'),
                              content: Text('このセットを削除しますか？（データも全て削除されます）'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('削除',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await DatabaseHelper.instance
                                .deleteFieldSet(fs.id!);
                            setState(() {
                              _fieldSetsFuture =
                                  DatabaseHelper.instance.getFieldSets();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
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
