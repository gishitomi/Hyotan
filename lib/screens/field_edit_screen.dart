// screens/field_edit_screen.dart
import 'package:flutter/material.dart';
import '../models/field.dart';

class FieldEditScreen extends StatefulWidget {
  final List<Field> fields;
  final Function(List<Field>) onSave;

  FieldEditScreen({required this.fields, required this.onSave});

  @override
  _FieldEditScreenState createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> {
  late List<Field> editableFields;

  @override
  void initState() {
    super.initState();
    editableFields =
        widget.fields
            .map(
              (f) => Field(
                id: f.id,
                fieldSetId: f.fieldSetId,
                name: f.name,
                type: f.type,
              ),
            )
            .toList();
  }

  void _addField() {
    setState(() {
      editableFields.add(Field(id: 0, fieldSetId: 0, name: '', type: 'text'));
    });
  }

  void _save() {
    widget.onSave(editableFields);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSV項目編集'),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _save, tooltip: '保存'),
        ],
      ),
      body: ListView.builder(
        itemCount: editableFields.length,
        itemBuilder: (context, index) {
          final field = editableFields[index];
          return ListTile(
            leading: Text('${index + 1}'),
            title: TextFormField(
              initialValue: field.name,
              onChanged: (value) {
                setState(() {
                  editableFields[index] = field.copyWith(name: value);
                });
              },
              decoration: InputDecoration(labelText: '項目名'),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  editableFields.removeAt(index);
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addField,
        child: Icon(Icons.add),
        tooltip: '項目を追加',
      ),
    );
  }
}
