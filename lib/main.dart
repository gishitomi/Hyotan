import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CsvApp());
}

class CsvApp extends StatelessWidget {
  const CsvApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSVデータ収集アプリ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
