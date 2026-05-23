/// 每日意图数据模型
class DailyIntention {
  final int? id;
  final String date;
  final String intention;
  final String? category;
  final int color;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyIntention({
    this.id,
    required this.date,
    required this.intention,
    this.category,
    this.color = 0xFF2196F3,
    this.isCompleted = false,
    this.completedAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyIntention copyWith({
    int? id,
    String? date,
    String? intention,
    String? category,
    int? color,
    bool? isCompleted,
    DateTime? completedAt,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyIntention(
      id: id ?? this.id,
      date: date ?? this.date,
      intention: intention ?? this.intention,
      category: category ?? this.category,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'intention': intention,
      'category': category,
      'color': color,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyIntention.fromMap(Map<String, dynamic> map) {
    return DailyIntention(
      id: map['id'] as int?,
      date: map['date'] as String,
      intention: map['intention'] as String,
      category: map['category'] as String?,
      color: map['color'] as int? ?? 0xFF2196F3,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum IntentionCategory {
  work('工作', 0xFF2196F3),
  health('健康', 0xFF4CAF50),
  learning('学习', 0xFFFF9800),
  relationships('关系', 0xFFE91E63),
  creativity('创意', 0xFF9C27B0),
  mindfulness('正念', 0xFF00BCD4),
  finance('财务', 0xFFFF5722),
  other('其他', 0xFF607D8B);

  final String label;
  final int color;
  const IntentionCategory(this.label, this.color);
}
