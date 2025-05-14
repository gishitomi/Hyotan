import 'package:flutter/material.dart';
import '../models/field_set.dart';
import '../db/database_helper.dart';

class FieldSetProvider extends ChangeNotifier {
  List<FieldSet> _fieldSets = [];
  bool _isLoading = false;

  List<FieldSet> get fieldSets => _fieldSets;
  bool get isLoading => _isLoading;

  Future<void> loadFieldSets() async {
    _isLoading = true;
    notifyListeners();
    _fieldSets = await DatabaseHelper.instance.getFieldSets();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFieldSet(FieldSet fieldSet) async {
    await DatabaseHelper.instance.insertFieldSet(fieldSet);
    await loadFieldSets();
  }

  Future<void> updateFieldSet(FieldSet fieldSet) async {
    await DatabaseHelper.instance.updateFieldSet(fieldSet);
    await loadFieldSets();
  }

  Future<void> deleteFieldSet(int id) async {
    await DatabaseHelper.instance.deleteFieldSet(id);
    await loadFieldSets();
  }
}
