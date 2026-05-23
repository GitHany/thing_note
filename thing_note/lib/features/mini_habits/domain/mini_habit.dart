/// 迷你习惯数据模型
class MiniHabit {
  final int? id;
  final String title;
  final String? description;
  final int durationSeconds;
  final String? icon;
  final int color;
  final String frequency;
  final int streakDays;
  final int bestStreak;
  final int totalCompletions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MiniHabit({
    this.id,
    required this.title,
    this.description,
    this.durationSeconds = 120,
    this.icon,
    this.color = 0xFF2196F3,
    this.frequency = 'daily',
    this.streakDays = 0,
    this.bestStreak = 0,
    this.totalCompletions = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOnFire => streakDays >= 7;

  String get durationLabel {
    if (durationSeconds <= 30) return '30秒';
    if (durationSeconds <= 60) return '1分钟';
    if (durationSeconds <= 120) return '2分钟';
    if (durationSeconds <= 300) return '5分钟';
    return '${(durationSeconds / 60).round()}分钟';
  }

  MiniHabit copyWith({
    int? id,
    String? title,
    String? description,
    int? durationSeconds,
    String? icon,
    int? color,
    String? frequency,
    int? streakDays,
    int? bestStreak,
    int? totalCompletions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MiniHabit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      streakDays: streakDays ?? this.streakDays,
      bestStreak: bestStreak ?? this.bestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'duration_seconds': durationSeconds,
      'icon': icon,
      'color': color,
      'frequency': frequency,
      'streak_days': streakDays,
      'best_streak': bestStreak,
      'total_completions': totalCompletions,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MiniHabit.fromMap(Map<String, dynamic> map) {
    return MiniHabit(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      durationSeconds: map['duration_seconds'] as int? ?? 120,
      icon: map['icon'] as String?,
      color: map['color'] as int? ?? 0xFF2196F3,
      frequency: map['frequency'] as String? ?? 'daily',
      streakDays: map['streak_days'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      totalCompletions: map['total_completions'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class MiniHabitLog {
  final int? id;
  final int habitId;
  final DateTime completedAt;
  final int durationActual;
  final String? note;

  const MiniHabitLog({
    this.id,
    required this.habitId,
    required this.completedAt,
    this.durationActual = 0,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'completed_at': completedAt.toIso8601String(),
      'duration_actual': durationActual,
      'note': note,
    };
  }

  factory MiniHabitLog.fromMap(Map<String, dynamic> map) {
    return MiniHabitLog(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      durationActual: map['duration_actual'] as int? ?? 0,
      note: map['note'] as String?,
    );
  }
}
