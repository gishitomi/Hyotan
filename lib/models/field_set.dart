// models/field_set.dart

class FieldSet {
  final int? id;
  final String name;

  FieldSet({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory FieldSet.fromMap(Map<String, dynamic> map) {
    return FieldSet(
      id: map['id'],
      name: map['name'],
    );
  }

  @override
  String toString() => 'FieldSet(id: $id, name: $name)';
}
