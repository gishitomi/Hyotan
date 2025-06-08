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
import 'package:horizontal_data_table/horizontal_data_table.dart';

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
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'CSV出力',
            onPressed: () => _exportCsv(context),
          ),
        ],
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

                  // データ取得後のentriesの並び順を調整

                  // 追加: ID（またはcreatedAt）昇順でソート（新しいデータが一番下になる）
                  entries.sort((a, b) =>
                      a.id!.compareTo(b.id!)); // idがnullの場合はcreatedAtで

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

                      return HorizontalDataTable(
                        leftHandSideColumnWidth: 60,
                        rightHandSideColumnWidth: 120.0 * columns.length +
                            180 +
                            60 +
                            60, // ← 180(日時) + 60(編集) + 60(削除)を追加
                        isFixedHeader: true,
                        headerWidgets: [
                          _buildHeaderWidget('No.', 60),
                          ...columns
                              .map((col) => _buildHeaderWidget(col, 120))
                              .toList(),
                          _buildHeaderWidget('日時', 180),
                          _buildHeaderWidget('編集', 60),
                          _buildHeaderWidget('削除', 60),
                        ],
                        leftSideItemBuilder: (context, index) {
                          return Container(
                            width: 60,
                            height: 56, // ← 高さを明示
                            alignment: Alignment.center,
                            child: Text('${index + 1}'),
                          );
                        },
                        rightSideItemBuilder: (context, index) {
                          final entry = entries[index];
                          return Container(
                            height: 56, // ← Row全体に高さを指定
                            child: Row(
                              children: [
                                ...columns.map((col) => Container(
                                      width: 120,
                                      alignment: Alignment.center,
                                      child: Text(
                                          entry.values[col]?.toString() ?? ''),
                                    )),
                                Container(
                                  width: 180,
                                  alignment: Alignment.center,
                                  child:
                                      Text(dateFormat.format(entry.createdAt)),
                                ),
                                Container(
                                  width: 60,
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Colors.blue, size: 20),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final fields = await DatabaseHelper
                                          .instance
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
                                Container(
                                  width: 60,
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    padding: EdgeInsets.zero,
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
                                ),
                              ],
                            ),
                          );
                        },
                        itemCount: entries.length,
                        rowSeparatorWidget:
                            Divider(height: 1, color: Colors.grey),
                        leftHandSideColBackgroundColor: Colors.white,
                        rightHandSideColBackgroundColor: Colors.white,
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

  // ヘッダー用ウィジェット
  Widget _buildHeaderWidget(String label, double width) {
    return Container(
      width: width,
      height: 56,
      alignment: Alignment.center,
      color: Colors.blue[50],
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
