// models/field.dart
class Field {
  final int? id;
  final int fieldSetId;
  final String name;
  final String type; // 例: 'text', 'number' など

  Field({
    this.id,
    required this.fieldSetId,
    required this.name,
    required this.type,
  });

  factory Field.fromMap(Map<String, dynamic> map) {
    return Field(
      id: map['id'] as int?,
      fieldSetId: map['fieldSetId'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'fieldSetId': fieldSetId, 'name': name, 'type': type};
  }
}
