// screens/csv_list_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'csv_entry_screen.dart';
import '../db/database_helper.dart'; // 追加
import '../models/entry.dart'; // 追加
import '../models/field.dart'; // 追加
import 'package:csv/csv.dart';
import 'package:intl/intl.dart'; // 追加
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CsvListScreen extends StatefulWidget {
  final String setName;
  final int fieldSetId;

  const CsvListScreen({
    Key? key,
    required this.setName,
    required this.fieldSetId,
  }) : super(key: key);

  @override
  State<CsvListScreen> createState() => _CsvListScreenState();
}

class _CsvListScreenState extends State<CsvListScreen> {
  late Future<List<Entry>> _entriesFuture;
  late Future<List<Field>> _fieldsFuture;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _fieldsFuture = DatabaseHelper.instance.getFields(widget.fieldSetId);
  }

  void _loadEntries() {
    _entriesFuture = DatabaseHelper.instance.getEntries(widget.fieldSetId);
  }

  // CSV出力処理
  Future<void> _exportCsv(BuildContext context) async {
    // データ取得
    final entries = await DatabaseHelper.instance.getEntries(widget.fieldSetId);
    final fields = await DatabaseHelper.instance.getFields(widget.fieldSetId);
    final columns = fields.map((f) => f.name).toList();

    // ヘッダー
    final csvData = [
      ['日時', ...columns]
    ];

    // データ行
    for (final entry in entries) {
      csvData.add([
        entry.createdAt.toString(),
        ...columns.map((col) => entry.values[col]?.toString() ?? ''),
      ]);
    }

    // CSV文字列生成
    final csvString = const ListToCsvConverter().convert(csvData);

    // 一時ディレクトリにCSVファイルを書き込み
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/data.csv';
    final file = File(path);
    await file.writeAsString(csvString);

    // 共有ダイアログ表示（メールやLINEなど）
    await Share.shareXFiles(
      [XFile(path)],
      text: 'CSVデータを送信します',
      subject: 'データ',
    );
  }

  // 日時フォーマット用
  final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hyo-tan（ひょうたん）'),
        actions: [
          // CSV出力ボタンのみ右上に残す
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'CSV出力',
            onPressed: () async {
              await _exportCsv(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Entry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('データがありません'));
          }
          final entries = snapshot.data!;

          // カラム名をFieldテーブルから取得
          return FutureBuilder<List<Field>>(
            future: _fieldsFuture,
            builder: (context, fieldSnapshot) {
              if (!fieldSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final columns = fieldSnapshot.data!.map((f) => f.name).toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('No.')),
                    ...columns.map((col) => DataColumn(label: Text(col))),
                    DataColumn(label: Text('日時')), // 日時を編集ボタンの左隣に
                    DataColumn(label: Text('')), // 操作列
                  ],
                  rows: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')), // 行番号
                        ...columns.map((col) => DataCell(
                            Text(entry.values[col]?.toString() ?? ''))),
                        DataCell(Text(
                            dateFormat.format(entry.createdAt))), // フォーマット済み日時
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              tooltip: '編集',
                              onPressed: () async {
                                // 編集画面へ遷移（CsvEntryScreenを編集用に使う場合）
                                final fields = await DatabaseHelper.instance
                                    .getFields(widget.fieldSetId);
                                final fieldNames =
                                    fields.map((f) => f.name).toList();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CsvEntryScreen(
                                      setName: widget.setName,
                                      fieldSetId: widget.fieldSetId,
                                      fields: fieldNames,
                                      entry:
                                          entry, // 編集用にentryを渡す（CsvEntryScreen側で対応必要）
                                    ),
                                  ),
                                );
                                setState(() {
                                  _loadEntries();
                                  _fieldsFuture = DatabaseHelper.instance
                                      .getFields(widget.fieldSetId);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: '削除',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('削除確認'),
                                    content: Text('このデータを削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text('削除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await DatabaseHelper.instance
                                      .deleteEntry(entry.id!);
                                  setState(() {
                                    _loadEntries();
                                  });
                                }
                              },
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      // 画面下部中央にやや小さめの丸いボタンを配置
      floatingActionButton: SizedBox(
        width: 64, // ← ここを小さく
        height: 64, // ← ここを小さく
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.add, size: 32, color: Colors.white), // ← アイコンも少し小さく
          onPressed: _isNavigating
              ? null
              : () async {
                  setState(() {
                    _isNavigating = true;
                  });
                  final fields = await DatabaseHelper.instance
                      .getFields(widget.fieldSetId);
                  final fieldNames = fields.map((f) => f.name).toList();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CsvEntryScreen(
                        setName: widget.setName,
                        fieldSetId: widget.fieldSetId,
                        fields: fieldNames,
                      ),
                    ),
                  );
                  setState(() {
                    _isNavigating = false;
                    _loadEntries();
                    _fieldsFuture =
                        DatabaseHelper.instance.getFields(widget.fieldSetId);
                  });
                },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 新規登録画面から戻ってきたときに再取得
  void _onAddEntry() async {
    // ...Navigator.push...
    // await Navigator.push(...);
    setState(() {
      _loadEntries();
    });
  }
}
