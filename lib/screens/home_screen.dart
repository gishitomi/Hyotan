// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'csv_entry_screen.dart';
import 'csv_list_screen.dart';
import 'field_edit_screen.dart';

// 仮のFieldSetモデル
class FieldSet {
  final int? id;
  final String name;
  FieldSet({this.id, required this.name});
}

// 仮のデータ取得関数（本来はDBから取得）
Future<List<FieldSet>> fetchFieldSets() async {
  // ここはDBアクセスに置き換えてください
  await Future.delayed(Duration(milliseconds: 300));
  return [
    FieldSet(id: 1, name: 'セット1'),
    FieldSet(id: 2, name: 'セット2'),
    FieldSet(id: 3, name: 'セット3'),
  ];
}

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
    _fieldSetsFuture = fetchFieldSets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CSVデータ収集アプリ')),
      body: FutureBuilder<List<FieldSet>>(
        future: _fieldSetsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final fieldSets = snapshot.data!;
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
                    onPressed: () {
                      // 項目編集画面へ遷移（編集用）
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FieldEditScreen(
                            setName: fs.name,
                            fields: [], // ここはDBから取得した項目リストを渡す
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // データ入力画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CsvEntryScreen(
                          setName: fs.name,
                          fields: ['項目1', '項目2', '項目3'], // 仮の項目リスト
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    // データ一覧画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CsvListScreen(
                          setName: fs.name,
                          entries: [
                            {
                              'createdAt': '2024-05-14T12:00:00',
                              'values': {'項目1': 'A', '項目2': 'B', '項目3': 'C'}
                            },
                            {
                              'createdAt': '2024-05-14T12:05:00',
                              'values': {'項目1': 'X', '項目2': 'Y', '項目3': 'Z'}
                            },
                          ], // 仮のエントリリスト
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
