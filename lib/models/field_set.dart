// models/field_set.dart

class FieldSet {
  final int? id;
  final String name;

  FieldSet({this.id, required this.name});

  factory FieldSet.fromMap(Map<String, dynamic> map) {
    return FieldSet(id: map['id'] as int?, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
