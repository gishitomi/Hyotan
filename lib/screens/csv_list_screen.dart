// screens/csv_list_screen.dart
import 'package:flutter/material.dart';

class CsvListScreen extends StatelessWidget {
  final String setName;
  final List<Map<String, dynamic>> entries; // サンプルデータ

  const CsvListScreen({Key? key, required this.setName, required this.entries})
    : super(key: key);

  void _exportCsv(BuildContext context) {
    // TODO: CSVエクスポート処理を実装
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('共有方法を選択'),
            children: [
              SimpleDialogOption(
                child: Text('メールで送信'),
                onPressed: () {
                  // TODO: メール送信処理
                  Navigator.pop(context);
                },
              ),
              SimpleDialogOption(
                child: Text('LINEで送信'),
                onPressed: () {
                  // TODO: LINE送信処理
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('データ一覧（$setName）')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final createdAt = entry['createdAt'] ?? '';
                final values = entry['values'] as Map<String, dynamic>? ?? {};
                return ListTile(
                  title: Text('[$createdAt]'),
                  subtitle: Text(
                    values.entries.map((e) => '${e.key}:${e.value}').join('  '),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _exportCsv(context),
              child: Text('CSVエクスポート'),
            ),
          ),
        ],
      ),
    );
  }
}
