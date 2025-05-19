import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // デスクトップ（Windows, macOS, Linux）のみsqflite_common_ffiを初期化
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const CsvApp());
}

class CsvApp extends StatelessWidget {
  const CsvApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyo-tan', // ← タイトルを変更
      theme: ThemeData(
        primarySwatch: Colors.green, // ← 緑色に変更
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true, // Material3を使う場合
      ),
      home: const HomeScreen(),
    );
  }
}
