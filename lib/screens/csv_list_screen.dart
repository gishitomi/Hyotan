// screens/csv_list_screen.dart
import 'package:flutter/material.dart';
import '../models/field.dart';

class CsvListScreen extends StatelessWidget {
  final List<Field> fields;
  final List<List<String>> entries; // 仮データ構造（後でDB連携）

  CsvListScreen({required this.fields, required this.entries});

  void _exportCsv(BuildContext context) {
    // TODO: CSV生成・共有処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSVを出力しました（仮）")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("入力一覧 & CSV出力"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _exportCsv(context),
            tooltip: "CSV出力",
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final row = entries[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(row.join(', ')),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  // TODO: 削除処理を実装
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("削除しました（仮）")),
                  );
                },
              ),
              onTap: () {
                // TODO: 編集画面へ遷移
              },
            ),
          );
        },
      ),
    );
  }
}
