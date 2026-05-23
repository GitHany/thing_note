class HabitReset {
  final int? id;
  final int habitId;
  final String? resetReason;
  final String resetDate;
  final int previousStreak;
  final int newStreak;
  final int isSoftReset;
  final DateTime createdAt;

  HabitReset({
    this.id,
    required this.habitId,
    this.resetReason,
    required this.resetDate,
    this.previousStreak = 0,
    this.newStreak = 0,
    this.isSoftReset = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'reset_reason': resetReason,
      'reset_date': resetDate,
      'previous_streak': previousStreak,
      'new_streak': newStreak,
      'is_soft_reset': isSoftReset,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitReset.fromMap(Map<String, dynamic> map) {
    return HabitReset(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      resetReason: map['reset_reason'] as String?,
      resetDate: map['reset_date'] as String,
      previousStreak: map['previous_streak'] as int? ?? 0,
      newStreak: map['new_streak'] as int? ?? 0,
      isSoftReset: map['is_soft_reset'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  HabitReset copyWith({
    int? id,
    int? habitId,
    String? resetReason,
    String? resetDate,
    int? previousStreak,
    int? newStreak,
    int? isSoftReset,
    DateTime? createdAt,
  }) {
    return HabitReset(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      resetReason: resetReason ?? this.resetReason,
      resetDate: resetDate ?? this.resetDate,
      previousStreak: previousStreak ?? this.previousStreak,
      newStreak: newStreak ?? this.newStreak,
      isSoftReset: isSoftReset ?? this.isSoftReset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> resetReasons = [
    'vacation',
    'illness',
    'travel',
    'adjustment',
    'restart',
    'other',
  ];

  static const Map<String, String> reasonLabels = {
    'vacation': '度假休息',
    'illness': '生病',
    'travel': '出差/旅行',
    'adjustment': '调整节奏',
    'restart': '重新开始',
    'other': '其他原因',
  };
}