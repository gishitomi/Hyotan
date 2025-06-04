// screens/field_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  late List<String> _types; // 追加: 各項目の型（'text', 'number', 'date'）
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.fields);
    _types = List.filled(_fields.length, 'text'); // デフォルトは全てテキスト
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-9487888965458679/8474773818',
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
        _types.add('text'); // 必ず型も追加
      });
    }
  }

  Future<void> _editField(int index) async {
    final oldName = _fields[index];
    final controller = TextEditingController(text: oldName);
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
    if (result != null && result.isNotEmpty && result != oldName) {
      setState(() {
        _fields[index] = result;
      });
      // ここでEntryのvaluesのキーも更新
      await DatabaseHelper.instance.renameEntryField(
        widget.fieldSetId!,
        oldName,
        result,
      );
    }
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
      _types.removeAt(index); // 型も同時に削除
    });
  }

  Future<void> _changeType(int index) async {
    String selectedType = _types[index];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('書式を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'text',
              groupValue: selectedType,
              title: Text('テキスト'),
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<String>(
              value: 'number',
              groupValue: selectedType,
              title: Text('数値'),
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<String>(
              value: 'date',
              groupValue: selectedType,
              title: Text('日付'),
              onChanged: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _types[index] = result;
      });
    }
  }

  void _saveFields() async {
    if (widget.fieldSetId == null) {
      // 新規セットの場合はセットを作成してIDを取得
      final newSetId = await DatabaseHelper.instance.insertFieldSet(
        FieldSet(name: widget.setName),
      );
      for (int i = 0; i < _fields.length; i++) {
        await DatabaseHelper.instance.insertField(
          Field(fieldSetId: newSetId, name: _fields[i], type: _types[i]),
        );
      }
    } else {
      // 既存セットの場合は項目を全削除して再登録（シンプルな方法）
      await DatabaseHelper.instance.deleteFieldsBySetId(widget.fieldSetId!);
      for (int i = 0; i < _fields.length; i++) {
        await DatabaseHelper.instance.insertField(
          Field(
              fieldSetId: widget.fieldSetId!,
              name: _fields[i],
              type: _types[i]),
        );
      }
    }
    Navigator.pop(context, true);
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
        title: Text('Hyo-tan（ひょうたん）'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _fields.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) => ListTile(
                title: TextFormField(
                  initialValue: _fields[index],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '項目名',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _fields[index] = value;
                    });
                  },
                ),
                // 書式変更ボタン
                leading: IconButton(
                  icon: Icon(
                    _types[index] == 'text'
                        ? Icons.text_fields
                        : _types[index] == 'number'
                            ? Icons.pin
                            : Icons.date_range,
                    color: Colors.blue,
                  ),
                  tooltip: '書式変更',
                  onPressed: () => _changeType(index),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeField(index),
                ),
                subtitle: Text(
                  _types[index] == 'text'
                      ? 'テキスト'
                      : _types[index] == 'number'
                          ? '数値'
                          : '日付',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('項目追加'),
                    onPressed: _addField,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('保存'),
                    onPressed: _saveFields,
                  ),
                ),
              ],
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
