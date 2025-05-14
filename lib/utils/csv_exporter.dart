import 'dart:convert';
import '../models/entry.dart';

class CsvExporter {
  /// entries: Entryのリスト
  /// fields: 出力したい項目名リスト（カラム順）
  static String exportToCsv(List<Entry> entries, List<String> fields) {
    final buffer = StringBuffer();

    // ヘッダー
    buffer.writeln(['createdAt', ...fields].join(','));

    // 各行
    for (final entry in entries) {
      final row = <String>[];
      row.add(entry.createdAt.toIso8601String());
      for (final field in fields) {
        final value = entry.values[field] ?? '';
        // カンマや改行を含む場合はダブルクォートで囲む
        final cell =
            value.toString().contains(',') || value.toString().contains('\n')
                ? '"${value.toString().replaceAll('"', '""')}"'
                : value.toString();
        row.add(cell);
      }
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }
}
