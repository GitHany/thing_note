/// 习惯追踪数据模型
class Habit {
  final int? id;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final int targetCount;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastCompletedAt;
  final DateTime createdAt;

  const Habit({
    this.id,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.targetCount = 1,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedAt,
    required this.createdAt,
  });

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    HabitFrequency? frequency,
    int? targetCount,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompletedAt,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCompletedToday {
    if (lastCompletedAt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCompleted = DateTime(lastCompletedAt!.year, lastCompletedAt!.month, lastCompletedAt!.day);
    return !lastCompleted.isBefore(today);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.name,
      'target_count': targetCount,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_completed_at': lastCompletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      targetCount: map['target_count'] as int? ?? 1,
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      lastCompletedAt: map['last_completed_at'] != null
          ? DateTime.parse(map['last_completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum HabitFrequency {
  daily,
  weekly,
  custom,
}

extension HabitFrequencyExtension on HabitFrequency {
  String get displayName {
    switch (this) {
      case HabitFrequency.daily:
        return '每天';
      case HabitFrequency.weekly:
        return '每周';
      case HabitFrequency.custom:
        return '自定义';
    }
  }
}

/// 习惯完成记录
class HabitLog {
  final int? id;
  final int habitId;
  final DateTime completedAt;
  final String? note;

  const HabitLog({
    this.id,
    required this.habitId,
    required this.completedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'completed_at': completedAt.toIso8601String(),
      'note': note,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      note: map['note'] as String?,
    );
  }
}