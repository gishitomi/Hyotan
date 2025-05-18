import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const CsvApp());
}

class CsvApp extends StatelessWidget {
  const CsvApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSVデータ収集アプリ',
      theme: ThemeData(
        primarySwatch: Colors.green, // ← 緑色に変更
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true, // Material3を使う場合
      ),
      home: const HomeScreen(),
    );
  }
}
