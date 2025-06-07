// screens/csv_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../db/database_helper.dart'; // ファイル冒頭でインポート
import '../models/entry.dart'; // 例: Entryクラスのパス
import '../models/field.dart'; // 追加: Fieldクラスのパス

class CsvEntryScreen extends StatefulWidget {
  final String setName;
  final int fieldSetId;
  final List<String> fields;
  final Entry? entry; // 追加: 編集用

  const CsvEntryScreen({
    Key? key,
    required this.setName,
    required this.fieldSetId,
    required this.fields,
    this.entry, // 追加: 編集用
  }) : super(key: key);

  @override
  State<CsvEntryScreen> createState() => _CsvEntryScreenState();
}

class _CsvEntryScreenState extends State<CsvEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field] = TextEditingController(
        text: widget.entry?.values[field] ?? '',
      );
    }
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
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _bannerAd.dispose();
    super.dispose();
  }

  void _saveEntry() async {
    final values = <String, String>{};
    for (var field in widget.fields) {
      values[field] = _controllers[field]?.text ?? '';
    }

    if (widget.entry != null) {
      // 編集の場合はupdate
      final updatedEntry = widget.entry!.copyWith(
        values: values,
        createdAt: DateTime.now(), // 必要に応じて元のcreatedAtを維持
      );
      await DatabaseHelper.instance.updateEntry(updatedEntry);
    } else {
      // 新規作成の場合はinsert
      final entry = Entry(
        fieldSetId: widget.fieldSetId,
        values: values,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertEntry(entry);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存しました')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hyo-tan（ひょうたん）'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Field>>(
          future: DatabaseHelper.instance.getFields(widget.fieldSetId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('エラーが発生しました'));
            }

            final fields = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: fields.length,
                    itemBuilder: (context, index) {
                      final field = fields[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers[field.name],
                                decoration:
                                    InputDecoration(labelText: field.name),
                                keyboardType: field.type == 'number'
                                    ? TextInputType.number
                                    : TextInputType.text,
                                readOnly: field.type == 'date',
                                onTap: field.type == 'date'
                                    ? () async {
                                        DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          _controllers[field.name]?.text =
                                              picked
                                                  .toIso8601String()
                                                  .split('T')
                                                  .first;
                                        }
                                      }
                                    : null,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'この項目の入力をクリア',
                              onPressed: () {
                                setState(() {
                                  _controllers[field.name]?.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _saveEntry, child: Text('保存')),
              ],
            );
          },
        ),
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
