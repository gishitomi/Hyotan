// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'csv_entry_screen.dart';
import 'csv_list_screen.dart';
import 'field_edit_screen.dart';
import '../db/database_helper.dart';
import '../models/field_set.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<FieldSet>> _fieldSetsFuture;

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _fieldSetsFuture = DatabaseHelper.instance.getFieldSets();
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

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // ← 追加
        title: Text('Hyo-tan（ひょうたん）'),
      ),
      body: Column(
        children: [
          // ヘッダー下にラベル行を追加（各項目の位置に合わせて調整）
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // CSVファイル名（旧: セット名）
                Expanded(
                  child: Text('CSVファイル名',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                // セット名編集ボタンの位置
                SizedBox(
                  width: 48, // アイコンボタンの幅に合わせて調整
                  child: Center(
                    child: Text('CSV名編集',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                // 項目編集ボタンの位置
                SizedBox(
                  width: 48, // アイコンボタンの幅に合わせて調整
                  child: Center(
                    child: Text('項目編集',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          // 既存のFutureBuilderをExpandedで包む
          Expanded(
            child: FutureBuilder<List<FieldSet>>(
              future: _fieldSetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('エラー: ${snapshot.error}'));
                }
                final fieldSets = snapshot.data!;
                if (fieldSets.isEmpty) {
                  // セットがない場合も「新しいセット」ボタンを表示
                  return ListView(
                    children: [
                      ListTile(
                        leading: Icon(Icons.add),
                        title: Text('新しいセット'),
                        onTap: () async {
                          // セット名入力ダイアログを表示
                          final controller = TextEditingController();
                          final setName = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('新しいCSVファイル名を入力'),
                              content: TextField(
                                controller: controller,
                                decoration: InputDecoration(labelText: 'CSVファイル名'),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                      context, controller.text.trim()),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (setName != null && setName.isNotEmpty) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FieldEditScreen(
                                  setName: setName,
                                  fields: [],
                                  types: [], // 追加
                                ),
                              ),
                            );
                            // ★ ここで再取得
                            if (result == true) {
                              setState(() {
                                _fieldSetsFuture =
                                    DatabaseHelper.instance.getFieldSets();
                              });
                            }
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(child: Text('セットがありません')),
                      ),
                    ],
                  );
                }
                return ListView(
                  children: [
                    ...fieldSets.map(
                      (fs) => Dismissible(
                        key: ValueKey(fs.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('削除確認'),
                              content: Text('このセットを削除しますか？'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('削除'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await DatabaseHelper.instance
                              .deleteFieldSet(fs.id ?? 0);
                          setState(() {
                            _fieldSetsFuture =
                                DatabaseHelper.instance.getFieldSets();
                          });
                        },
                        child: ListTile(
                          title: Text(fs.name), // ←ここはDBのnameをそのまま使う（CSVファイル名として）
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // セット名編集ボタン
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'CSV名編集',
                                onPressed: () async {
                                  final controller =
                                      TextEditingController(text: fs.name);
                                  final newName = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('CSVファイル名を編集'),
                                      content: TextField(
                                        controller: controller,
                                        decoration:
                                            InputDecoration(labelText: 'CSVファイル名'),
                                        autofocus: true,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, controller.text.trim()),
                                          child: Text('保存'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (newName != null &&
                                      newName.isNotEmpty &&
                                      newName != fs.name) {
                                    // DBを更新
                                    await DatabaseHelper.instance
                                        .updateFieldSet(
                                      fs.copyWith(name: newName),
                                    );
                                    setState(() {
                                      _fieldSetsFuture = DatabaseHelper.instance
                                          .getFieldSets();
                                    });
                                  }
                                },
                              ),
                              // 項目編集ボタン
                              IconButton(
                                icon: Icon(Icons.view_column,
                                    color: Colors.green),
                                tooltip: '項目編集',
                                onPressed: () async {
                                  if (fs.id == null) return;
                                  final fields = await DatabaseHelper.instance
                                      .getFields(fs.id!);
                                  final fieldNames =
                                      fields.map((f) => f.name).toList();
                                  final types = await DatabaseHelper.instance
                                      .getFieldTypes(fs.id!); // 追加
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FieldEditScreen(
                                        setName: fs.name,
                                        fieldSetId:
                                            fs.id!, // ← nullでないことを保証してint型に変換
                                        fields: fieldNames,
                                        types: types, // 追加
                                      ),
                                    ),
                                  );
                                  setState(() {
                                    _fieldSetsFuture =
                                        DatabaseHelper.instance.getFieldSets();
                                  });
                                },
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (fs.id == null) return; // nullなら何もしない
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CsvListScreen(
                                  setName: fs.name,
                                  fieldSetId: fs.id ??
                                      0, // nullなら0を使う（ただし0が有効なIDでない場合のみ）
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            if (fs.id == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CsvListScreen(
                                  setName: fs.name,
                                  fieldSetId: fs.id!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.add),
                      title: Text('新しいセット'),
                      onTap: () async {
                        // セット名入力ダイアログを表示
                        final controller = TextEditingController();
                        final setName = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('新しいCSVファイル名を入力'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(labelText: 'CSVファイル名'),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                    context, controller.text.trim()),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (setName != null && setName.isNotEmpty) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FieldEditScreen(
                                setName: setName,
                                fields: [],
                                types: [], // 追加
                              ),
                            ),
                          );
                          // ★ ここで再取得
                          if (result == true) {
                            setState(() {
                              _fieldSetsFuture =
                                  DatabaseHelper.instance.getFieldSets();
                            });
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isAdLoaded
          ? SizedBox(
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            )
          : null,
    );
  }
}
