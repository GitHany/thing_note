class HabitStreak {
  final int? id;
  final String habitName;
  final int currentStreak;
  final int longestStreak;
  final String? lastCheckIn;
  final String? bestRecord;
  final DateTime createdAt;

  HabitStreak({
    this.id,
    required this.habitName,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckIn,
    this.bestRecord,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_name': habitName,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_check_in': lastCheckIn,
      'best_record': bestRecord,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitStreak.fromMap(Map<String, dynamic> map) {
    return HabitStreak(
      id: map['id'] as int?,
      habitName: map['habit_name'] as String,
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      lastCheckIn: map['last_check_in'] as String?,
      bestRecord: map['best_record'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  HabitStreak copyWith({
    int? id,
    String? habitName,
    int? currentStreak,
    int? longestStreak,
    String? lastCheckIn,
    String? bestRecord,
    DateTime? createdAt,
  }) {
    return HabitStreak(
      id: id ?? this.id,
      habitName: habitName ?? this.habitName,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      bestRecord: bestRecord ?? this.bestRecord,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}