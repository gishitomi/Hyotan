// screens/csv_entry_screen.dart
import 'package:flutter/material.dart';
import '../models/field.dart';

class CsvEntryScreen extends StatefulWidget {
  final List<Field> fields;

  CsvEntryScreen({required this.fields});

  @override
  _CsvEntryScreenState createState() => _CsvEntryScreenState();
}

class _CsvEntryScreenState extends State<CsvEntryScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field.id ?? 0] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveEntry() {
    final values = widget.fields.map((field) => _controllers[field.id ?? 0]?.text ?? '').toList();
    // 保存処理（後で実装）
    print("入力内容: \$values");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("データを保存しました（仮）")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CSV データ入力")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: widget.fields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextField(
              controller: _controllers[field.id ?? 0],
              decoration: InputDecoration(
                labelText: field.name,
                border: OutlineInputBorder(),
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveEntry,
        child: Icon(Icons.save),
        tooltip: '保存',
      ),
    );
  }
}
