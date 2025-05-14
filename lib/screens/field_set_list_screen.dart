// screens/field_set_list_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/field_set.dart';
import 'field_editor_screen.dart';

class FieldSetListScreen extends StatefulWidget {
  @override
  _FieldSetListScreenState createState() => _FieldSetListScreenState();
}

class _FieldSetListScreenState extends State<FieldSetListScreen> {
  List<FieldSet> _fieldSets = [];
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFieldSets();
  }

  Future<void> _loadFieldSets() async {
    final sets = await DatabaseHelper.instance.getFieldSets();
    setState(() {
      _fieldSets = sets;
    });
  }

  Future<void> _addFieldSet(String name) async {
    final newSet = FieldSet(name: name);
    await DatabaseHelper.instance.insertFieldSet(newSet);
    _nameController.clear();
    _loadFieldSets();
  }

  Future<void> _deleteFieldSet(int id) async {
    await DatabaseHelper.instance.deleteFieldSet(id);
    _loadFieldSets();
  }

  void _showAddSetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("新しい項目セット"),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: "セット名"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                _addFieldSet(_nameController.text);
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
      appBar: AppBar(
        title: Text('CSV 項目セット一覧'),
      ),
      body: ListView.builder(
        itemCount: _fieldSets.length,
        itemBuilder: (context, index) {
          final set = _fieldSets[index];
          return ListTile(
            title: Text(set.name),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteFieldSet(set.id!),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FieldEditorScreen(
                  fieldSetId: set.id!,
                  fieldSetName: set.name,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSetDialog,
        child: Icon(Icons.add),
        tooltip: '項目セットを追加',
      ),
    );
  }
}
