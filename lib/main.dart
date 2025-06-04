import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    // デスクトップ（Windows, macOS, Linux）のみsqflite_common_ffiを初期化
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await MobileAds.instance.initialize();
  }
  runApp(const CsvApp());
}

class CsvApp extends StatelessWidget {
  const CsvApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyo-tan（ひょうたん）',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // ← ここを青に
        useMaterial3: true,
        // もしprimarySwatchを使っている場合はこちらも
        // primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // ← これを追加
    );
  }
}
