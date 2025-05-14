// models/entry.dart

class Entry {
  int? id;
  int fieldSetId; // どの項目セットに基づいたエントリか
  Map<String, String> data; // key: 項目名, value: 入力された内容
  DateTime createdAt;

  Entry({
    this.id,
    required this.fieldSetId,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_set_id': fieldSetId,
      'data': dataEncode(data),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      fieldSetId: map['field_set_id'],
      data: dataDecode(map['data']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static String dataEncode(Map<String, String> data) {
    return data.entries.map((e) => '${e.key}:${e.value}').join(';');
  }

  static Map<String, String> dataDecode(String encoded) {
    final map = <String, String>{};
    for (var pair in encoded.split(';')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }
}
