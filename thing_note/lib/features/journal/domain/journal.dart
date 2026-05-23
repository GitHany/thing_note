class Journal {
  final int? id;
  final String date;
  final String content;
  final String? mood;
  final String? weather;
  final bool isPrivate;
  final List<int>? linkedRecordIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Journal({
    this.id,
    required this.date,
    required this.content,
    this.mood,
    this.weather,
    this.isPrivate = false,
    this.linkedRecordIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'content': content,
      'mood': mood,
      'weather': weather,
      'is_private': isPrivate ? 1 : 0,
      'linked_record_ids': linkedRecordIds?.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Journal.fromMap(Map<String, dynamic> map) {
    return Journal(
      id: map['id'] as int?,
      date: map['date'] as String,
      content: map['content'] as String? ?? '',
      mood: map['mood'] as String?,
      weather: map['weather'] as String?,
      isPrivate: (map['is_private'] as int?) == 1,
      linkedRecordIds: map['linked_record_ids'] != null 
          ? (map['linked_record_ids'] as String)
              .split(',')
              .where((e) => e.isNotEmpty)
              .map((e) => int.parse(e))
              .toList()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Journal copyWith({
    int? id,
    String? date,
    String? content,
    String? mood,
    String? weather,
    bool? isPrivate,
    List<int>? linkedRecordIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Journal(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      isPrivate: isPrivate ?? this.isPrivate,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}