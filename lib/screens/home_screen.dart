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
        title: Text('Hyo-tan（ひょうたん）'), // ← ここを変更
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
            // セットがない場合も「新しいセット」ボタンを表示
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
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(child: Text('セットがありません')),
                ),
              ],
            );
          }
          return ListView(
            children: [
              ...fieldSets.map(
                (fs) => Dismissible(
                  key: ValueKey(fs.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('削除確認'),
                        content: Text('このセットを削除しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('削除'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await DatabaseHelper.instance.deleteFieldSet(fs.id ?? 0);
                    setState(() {
                      _fieldSetsFuture = DatabaseHelper.instance.getFieldSets();
                    });
                  },
                  child: ListTile(
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
                                  decoration:
                                      InputDecoration(labelText: 'セット名'),
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
                            if (fs.id == null) return;
                            final fields =
                                await DatabaseHelper.instance.getFields(fs.id!);
                            final fieldNames =
                                fields.map((f) => f.name).toList();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FieldEditScreen(
                                  setName: fs.name,
                                  fieldSetId: fs.id!, // ← nullでないことを保証してint型に変換
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
                      ],
                    ),
                    onTap: () async {
                      if (fs.id == null) return; // nullなら何もしない
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CsvListScreen(
                            setName: fs.name,
                            fieldSetId:
                                fs.id ?? 0, // nullなら0を使う（ただし0が有効なIDでない場合のみ）
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      if (fs.id == null) return;
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
              ),
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
            ],
          );
        },
      ),
    );
  }
}
