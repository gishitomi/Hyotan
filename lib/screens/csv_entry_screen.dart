// screens/csv_entry_screen.dart
import 'package:flutter/material.dart';

class CsvEntryScreen extends StatefulWidget {
  final String setName;
  final List<String> fields; // 項目名リスト

  const CsvEntryScreen({Key? key, required this.setName, required this.fields})
    : super(key: key);

  @override
  State<CsvEntryScreen> createState() => _CsvEntryScreenState();
}

class _CsvEntryScreenState extends State<CsvEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field] = TextEditingController();
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
    final values = <String, String>{};
    for (var field in widget.fields) {
      values[field] = _controllers[field]?.text ?? '';
    }
    // TODO: DB保存処理を追加
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('保存しました')));
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
            ...widget.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _controllers[field],
                  decoration: InputDecoration(labelText: field),
                ),
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
