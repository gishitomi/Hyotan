// models/field.dart
class Field {
  final int? id;
  final int fieldSetId;
  final String name;
  final String type;

  Field({
    this.id,
    required this.fieldSetId,
    required this.name,
    required this.type,
  });

  Field copyWith({
    int? id,
    int? fieldSetId,
    String? name,
    String? type,
  }) {
    return Field(
      id: id ?? this.id,
      fieldSetId: fieldSetId ?? this.fieldSetId,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  factory Field.fromMap(Map<String, dynamic> map) {
    return Field(
      id: map['id'],
      fieldSetId: map['fieldSetId'],
      name: map['name'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fieldSetId': fieldSetId,
      'name': name,
      'type': type,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
