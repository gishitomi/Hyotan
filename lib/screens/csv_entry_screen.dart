// screens/csv_entry_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart'; // ファイル冒頭でインポート
import '../models/entry.dart'; // 例: Entryクラスのパス

class CsvEntryScreen extends StatefulWidget {
  final String setName;
  final int fieldSetId;
  final List<String> fields;
  final Entry? entry; // 追加: 編集用

  const CsvEntryScreen({
    Key? key,
    required this.setName,
    required this.fieldSetId,
    required this.fields,
    this.entry, // 追加: 編集用
  }) : super(key: key);

  @override
  State<CsvEntryScreen> createState() => _CsvEntryScreenState();
}

class _CsvEntryScreenState extends State<CsvEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field] = TextEditingController(
        text: widget.entry?.values[field] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveEntry() async {
    final values = <String, String>{};
    for (var field in widget.fields) {
      values[field] = _controllers[field]?.text ?? '';
    }
    // Entryインスタンスを生成して保存
    final entry = Entry(
      fieldSetId: widget.fieldSetId,
      values: values,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertEntry(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存しました')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('データ入力（${widget.setName}）')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.fields.length,
                itemBuilder: (context, index) {
                  final field = widget.fields[index];
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _controllers[field],
                          decoration: InputDecoration(labelText: field),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'この項目の入力をクリア',
                        onPressed: () {
                          setState(() {
                            _controllers[field]?.clear(); // ★値をクリアするだけ
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveEntry, child: Text('保存')),
          ],
        ),
      ),
    );
  }
}
