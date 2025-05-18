// screens/field_edit_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart'; // 必要に応じて追加
import '../models/field.dart'; // 追加
import '../models/field_set.dart'; // 追加

class FieldEditScreen extends StatefulWidget {
  final String setName;
  final int? fieldSetId;
  final List<String> fields; // 項目名リスト

  const FieldEditScreen(
      {Key? key, required this.setName, this.fieldSetId, required this.fields})
      : super(key: key);

  @override
  State<FieldEditScreen> createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> {
  late List<String> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.fields);
  }

  void _addField() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('項目追加'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: '項目名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('追加'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _fields.add(result);
      });
    }
  }

  void _editField(int index) async {
    final controller = TextEditingController(text: _fields[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('項目編集'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: '項目名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _fields[index] = result;
      });
    }
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  void _saveFields() async {
    if (widget.fieldSetId == null) {
      // 新規セットの場合はセットを作成してIDを取得
      final newSetId = await DatabaseHelper.instance.insertFieldSet(
        FieldSet(name: widget.setName),
      );
      for (final name in _fields) {
        await DatabaseHelper.instance.insertField(
          Field(fieldSetId: newSetId, name: name, type: 'text'),
        );
      }
    } else {
      // 既存セットの場合は項目を全削除して再登録（シンプルな方法）
      await DatabaseHelper.instance.deleteFieldsBySetId(widget.fieldSetId!);
      for (final name in _fields) {
        await DatabaseHelper.instance.insertField(
          Field(fieldSetId: widget.fieldSetId!, name: name, type: 'text'),
        );
      }
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('項目編集（${widget.setName}）')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _fields.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) => ListTile(
                title: Text(_fields[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editField(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeField(index),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('項目追加'),
              onPressed: _addField,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveFields,
              child: Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
