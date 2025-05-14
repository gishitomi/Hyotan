// lib/screens/entry_list_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/field.dart';
import '../models/field_set.dart';
import '../models/entry.dart';
import '../db/database_helper.dart';
import 'entry_input_screen.dart';

class EntryListScreen extends StatefulWidget {
  final FieldSet fieldSet;

  const EntryListScreen({required this.fieldSet, Key? key}) : super(key: key);

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  List<Field> _fields = [];
  List<Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadFieldsAndEntries();
  }

  Future<void> _loadFieldsAndEntries() async {
    final fields = await DatabaseHelper.instance.fetchFieldsBySetId(
      widget.fieldSet.id!,
    );
    final entries = await DatabaseHelper.instance.fetchEntriesBySetId(
      widget.fieldSet.id!,
    );
    setState(() {
      _fields = fields;
      _entries = entries;
    });
  }

  void _navigateToInputScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EntryInputScreen(
              fieldSetId: widget.fieldSet.id!,
              fieldSetName: widget.fieldSet.name,
              fields: _fields,
            ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('新しいデータを追加しました')));
      await _loadFieldsAndEntries();
    }
  }

  Future<void> _exportCSV() async {
    final header = _fields.map((f) => f.name).toList();
    final rows = _entries.map(
      (entry) => header.map((h) => entry.data[h] ?? '').toList(),
    );

    final csv = StringBuffer();
    csv.writeln(header.join(','));
    for (var row in rows) {
      csv.writeln(row.join(','));
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/${widget.fieldSet.name}_data.csv';
    final file = File(path);
    await file.writeAsString(csv.toString());

    Share.shareXFiles([XFile(path)], text: '${widget.fieldSet.name}のCSVデータ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.fieldSet.name} の一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _exportCSV,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToInputScreen,
          ),
        ],
      ),
      body:
          _entries.isEmpty
              ? const Center(child: Text('データがありません'))
              : ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        _fields.map((f) => entry.data[f.name] ?? '').join(', '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await DatabaseHelper.instance.deleteEntry(entry.id!);
                          await _loadFieldsAndEntries();
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
