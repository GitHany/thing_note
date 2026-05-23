/// Grateful Notes 数据模型
class GratefulNote {
  final int? id;
  final DateTime date;
  final String content;
  final String? category;
  final int moodLevel; // 记录时的情绪
  final DateTime createdAt;

  const GratefulNote({
    this.id,
    required this.date,
    required this.content,
    this.category,
    this.moodLevel = 3,
    required this.createdAt,
  });

  GratefulNote copyWith({
    int? id,
    DateTime? date,
    String? content,
    String? category,
    int? moodLevel,
    DateTime? createdAt,
  }) {
    return GratefulNote(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      category: category ?? this.category,
      moodLevel: moodLevel ?? this.moodLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'category': category,
      'mood_level': moodLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GratefulNote.fromMap(Map<String, dynamic> map) {
    return GratefulNote(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String,
      category: map['category'] as String?,
      moodLevel: map['mood_level'] as int? ?? 3,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 感恩统计
class GratefulStats {
  final int totalNotes;
  final int streakDays;
  final Map<String, int> byCategory;
  final double avgMoodLevel;

  const GratefulStats({
    this.totalNotes = 0,
    this.streakDays = 0,
    this.byCategory = const {},
    this.avgMoodLevel = 0,
  });
}