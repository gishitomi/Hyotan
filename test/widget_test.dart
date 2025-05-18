import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyotan/main.dart'; // ← プロジェクト名に合わせて修正
import 'package:hyotan/db/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // 追加

void main() {
  // 追加: FFIの初期化
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('アプリが HomeScreen を表示するか確認', (WidgetTester tester) async {
    await tester.pumpWidget(CsvApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CSVデータ収集アプリ'), findsOneWidget);
  });
}
