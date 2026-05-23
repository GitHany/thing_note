/// Repository for habit check-in data operations
class HabitCheckinWidgetRepository {
  Future<List<HabitCheckin>> getTodayHabits() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      HabitCheckin(id: 1, name: '早起', isCompletedToday: true, streak: 7, completionRate: 85),
      HabitCheckin(id: 2, name: '阅读30分钟', isCompletedToday: false, streak: 3, completionRate: 60),
      HabitCheckin(id: 3, name: '运动', isCompletedToday: false, streak: 0, completionRate: 45),
    ];
  }

  Future<void> toggleCheckin(int habitId, bool completed) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> addHabit(String name) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Data model for habit check-in
class HabitCheckin {
  final int id;
  final String name;
  final bool isCompletedToday;
  final int streak;
  final int completionRate;

  HabitCheckin({
    required this.id,
    required this.name,
    this.isCompletedToday = false,
    this.streak = 0,
    this.completionRate = 0,
  });

  factory HabitCheckin.fromMap(Map<String, dynamic> map) {
    return HabitCheckin(
      id: map['id'] as int,
      name: map['name'] as String,
      isCompletedToday: (map['is_completed_today'] as int?) == 1,
      streak: map['streak'] as int? ?? 0,
      completionRate: map['completion_rate'] as int? ?? 0,
    );
  }
}