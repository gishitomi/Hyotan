// lib/screens/entry_input_screen.dart
import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/entry.dart';
import '../db/database_helper.dart';

class EntryInputScreen extends StatefulWidget {
  final int fieldSetId;
  final String fieldSetName;
  final List<Field> fields;

  const EntryInputScreen({
    required this.fieldSetId,
    required this.fieldSetName,
    required this.fields,
    Key? key,
  }) : super(key: key);

  @override
  _EntryInputScreenState createState() => _EntryInputScreenState();
}

class _EntryInputScreenState extends State<EntryInputScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final values = <String, String>{};
    for (var field in widget.fields) {
      values[field.name] = _controllers[field.name]?.text ?? '';
    }

    final entry = Entry(
      id: null,
      fieldSetId: widget.fieldSetId,
      data: values,
    );

    await DatabaseHelper.instance.insertEntry(entry);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('データを保存しました')),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.fieldSetName} に入力'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            for (var field in widget.fields)
              TextField(
                controller: _controllers[field.name],
                decoration: InputDecoration(labelText: field.name),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEntry,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
