// screens/field_editor_screen.dart
import 'package:flutter/material.dart';
import '../models/field.dart';
import '../db/database_helper.dart';

class FieldEditorScreen extends StatefulWidget {
  final int fieldSetId;
  final String fieldSetName;

  FieldEditorScreen({required this.fieldSetId, required this.fieldSetName});

  @override
  _FieldEditorScreenState createState() => _FieldEditorScreenState();
}

class _FieldEditorScreenState extends State<FieldEditorScreen> {
  List<Field> _fields = [];
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final fields = await DatabaseHelper.instance.fetchFieldsBySetId(
      widget.fieldSetId,
    );
    setState(() {
      _fields = fields;
    });
  }

  Future<void> _addField(String name) async {
    final newField = Field(
      fieldSetId: widget.fieldSetId,
      name: name,
      type: 'text', // デフォルトのフィールドタイプを指定
    );
    await DatabaseHelper.instance.insertField(newField);
    _nameController.clear();
    _loadFields();
  }

  Future<void> _deleteField(int id) async {
    await DatabaseHelper.instance.deleteField(id);
    _loadFields();
  }

  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("新しい項目"),
            content: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "項目名"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("キャンセル"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    _addField(_nameController.text);
                    Navigator.pop(context);
                  }
                },
                child: Text("追加"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.fieldSetName} の項目編集')),
      body: ListView.builder(
        itemCount: _fields.length,
        itemBuilder: (context, index) {
          final field = _fields[index];
          return ListTile(
            title: Text(field.name),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteField(field.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFieldDialog,
        child: Icon(Icons.add),
        tooltip: '項目を追加',
      ),
    );
  }
}
