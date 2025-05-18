// models/entry.dart

class Entry {
  final int? id;
  final int fieldSetId;
  final Map<String, dynamic> values;
  final DateTime createdAt;

  Entry({
    this.id,
    required this.fieldSetId,
    required this.values,
    required this.createdAt,
  });

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as int?,
      fieldSetId: map['fieldSetId'] as int,
      values: Map<String, dynamic>.from(map['values'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldSetId': fieldSetId,
      'values': values,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
