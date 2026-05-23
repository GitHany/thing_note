/// Habit Stacking 数据模型
class HabitChain {
  final int? id;
  final String name;
  final List<HabitStackItem> items;
  final DateTime? lastCompleted;
  final int streak;

  const HabitChain({
    this.id,
    required this.name,
    this.items = const [],
    this.lastCompleted,
    this.streak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'items': items.map((e) => e.toMap()).toList(),
      'last_completed': lastCompleted?.toIso8601String(),
      'streak': streak,
    };
  }
}

class HabitStackItem {
  final String habit;
  final String? cue; // 触发线索
  final int durationMinutes;

  const HabitStackItem({
    required this.habit,
    this.cue,
    this.durationMinutes = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'habit': habit,
      'cue': cue,
      'duration_minutes': durationMinutes,
    };
  }
}