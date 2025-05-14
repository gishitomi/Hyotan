// lib/utils/csv_export_helper.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/field.dart';
import '../models/entry.dart';

class CsvExportHelper {
  static Future<void> exportAndShareCsv(
    List<Field> fields,
    List<Entry> entries,
    String fileName,
  ) async {
    try {
      // ヘッダー作成
      final headers = fields.map((f) => f.name).toList();

      // データ行作成
      final dataRows =
          entries.map((entry) {
            return fields.map((field) => entry.data[field.name] ?? '').toList();
          }).toList();

      // CSVに変換
      final csv = const ListToCsvConverter().convert([headers, ...dataRows]);

      // 一時ファイルに保存
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.csv');
      await file.writeAsString(csv);

      // 共有
      await Share.shareXFiles([XFile(file.path)], text: '$fileName を共有します');
    } catch (e) {
      print('CSV出力エラー: \$e');
    }
  }
}
