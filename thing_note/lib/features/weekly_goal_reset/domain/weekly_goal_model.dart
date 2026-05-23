class WeeklyGoal {
  final int id;
  final String weekStart;
  final String goalTitle;
  final double? targetValue;
  final double currentValue;
  final bool isCompleted;
  final bool isReset;
  final DateTime createdAt;

  WeeklyGoal({
    required this.id,
    required this.weekStart,
    required this.goalTitle,
    this.targetValue,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isReset = false,
    required this.createdAt,
  });

  factory WeeklyGoal.fromMap(Map<String, dynamic> map) {
    return WeeklyGoal(
      id: map['id'] as int,
      weekStart: map['week_start'] as String,
      goalTitle: map['goal_title'] as String,
      targetValue: map['target_value'] as double?,
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0,
      isCompleted: (map['is_completed'] as int?) == 1,
      isReset: (map['is_reset'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_start': weekStart,
      'goal_title': goalTitle,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_completed': isCompleted ? 1 : 0,
      'is_reset': isReset ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get progress => targetValue != null && targetValue! > 0
      ? (currentValue / targetValue!).clamp(0.0, 1.0)
      : 0.0;
}

class WeeklyResetStats {
  final int totalWeeks;
  final int completedWeeks;
  final double averageCompletion;
  final List<WeeklyGoal> currentGoals;
  final List<WeeklyGoal> lastWeekGoals;

  WeeklyResetStats({
    required this.totalWeeks,
    required this.completedWeeks,
    required this.averageCompletion,
    required this.currentGoals,
    required this.lastWeekGoals,
  });
}