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
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  // ソート状態を保持
  String? _sortColumn;
  bool _sortAscending = true;

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  // Stateクラスのフィールドにコントローラを追加
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _fieldsFuture = DatabaseHelper.instance.getFields(widget.fieldSetId);

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-9487888965458679/8474773818', // ←あなたのバナー広告ユニットID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
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
    final csvConverter = ListToCsvConverter(eol: '\n');
    final csvString = csvConverter.convert(csvData);

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
      ),
      body: Column(
        children: [
          // 上部バナー広告
          if (_isAdLoaded)
            SizedBox(
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
          // 既存の画面内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<Entry>>(
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
                  var entries = snapshot.data!;

                  return FutureBuilder<List<Field>>(
                    future: _fieldsFuture,
                    builder: (context, fieldSnapshot) {
                      if (!fieldSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final columns =
                          fieldSnapshot.data!.map((f) => f.name).toList();

                      // ソート処理
                      if (_sortColumn != null) {
                        if (_sortColumn == 'No.') {
                          entries.sort((a, b) => _sortAscending
                              ? a.id!.compareTo(b.id!)
                              : b.id!.compareTo(a.id!));
                        } else if (_sortColumn == '日時') {
                          entries.sort((a, b) => _sortAscending
                              ? a.createdAt.compareTo(b.createdAt)
                              : b.createdAt.compareTo(a.createdAt));
                        } else {
                          entries.sort((a, b) {
                            final av = a.values[_sortColumn]?.toString() ?? '';
                            final bv = b.values[_sortColumn]?.toString() ?? '';
                            return _sortAscending
                                ? av.compareTo(bv)
                                : bv.compareTo(av);
                          });
                        }
                      }

                      return Scrollbar(
                        thumbVisibility: true,
                        controller: _horizontalScrollController, // 追加
                        child: GestureDetector(
                          behavior:
                              HitTestBehavior.translucent, // ← これで一覧外のスワイプも検知
                          onHorizontalDragUpdate: (details) {
                            _horizontalScrollController.jumpTo(
                              _horizontalScrollController.offset -
                                  details.delta.dx,
                            );
                          },
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController, // 追加
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              sortColumnIndex: _sortColumn == null
                                  ? null
                                  : (() {
                                      if (_sortColumn == 'No.') return 0;
                                      if (_sortColumn == '日時')
                                        return columns.length + 1;
                                      final idx = columns.indexOf(_sortColumn!);
                                      return idx == -1 ? null : idx + 1;
                                    })(),
                              sortAscending: _sortAscending,
                              columns: [
                                DataColumn(label: Text('削除')),
                                DataColumn(label: Text('編集')), // ← 編集ボタン用の列を追加
                                DataColumn(label: Text('No.')),
                                ...columns
                                    .map((col) => DataColumn(label: Text(col))),
                                DataColumn(label: Text('日時')),
                              ],
                              rows: List.generate(entries.length, (index) {
                                final entry = entries[index];
                                return DataRow(
                                  cells: [
                                    // 削除ボタンセル（左端）
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('削除確認'),
                                              content: Text('このデータを削除しますか？'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: Text('キャンセル'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
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
                                    ),
                                    // 編集ボタンセル（削除の右側）
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () async {
                                          final fields = await DatabaseHelper
                                              .instance
                                              .getFields(widget.fieldSetId);
                                          final fieldNames = fields
                                              .map((f) => f.name)
                                              .toList();
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CsvEntryScreen(
                                                setName: widget.setName,
                                                fieldSetId: widget.fieldSetId,
                                                fields: fieldNames,
                                                entry: entry,
                                              ),
                                            ),
                                          );
                                          setState(() {
                                            _loadEntries();
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(Text('${index + 1}')),
                                    // ↓ ここを修正：ContainerやBoxDecorationを外してTextだけに戻す
                                    ...columns.map((col) => DataCell(
                                          Text(entry.values[col]?.toString() ??
                                              ''),
                                        )),
                                    DataCell(Text(
                                        dateFormat.format(entry.createdAt))),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
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
