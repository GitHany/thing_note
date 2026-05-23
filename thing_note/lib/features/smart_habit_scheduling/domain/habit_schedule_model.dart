class HabitSchedule {
  final int id;
  final int habitId;
  final int? scheduledHour;
  final int? scheduledMinute;
  final int priority;
  final int? energyLevelNeeded;
  final bool isEnabled;
  final DateTime? lastExecuted;
  final int successCount;
  final DateTime createdAt;

  HabitSchedule({
    required this.id,
    required this.habitId,
    this.scheduledHour,
    this.scheduledMinute,
    this.priority = 1,
    this.energyLevelNeeded,
    this.isEnabled = true,
    this.lastExecuted,
    this.successCount = 0,
    required this.createdAt,
  });

  factory HabitSchedule.fromMap(Map<String, dynamic> map) {
    return HabitSchedule(
      id: map['id'] as int,
      habitId: map['habit_id'] as int,
      scheduledHour: map['scheduled_hour'] as int?,
      scheduledMinute: map['scheduled_minute'] as int?,
      priority: map['priority'] as int? ?? 1,
      energyLevelNeeded: map['energy_level_needed'] as int?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      lastExecuted: map['last_executed'] != null
          ? DateTime.parse(map['last_executed'] as String)
          : null,
      successCount: map['success_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'scheduled_hour': scheduledHour,
      'scheduled_minute': scheduledMinute,
      'priority': priority,
      'energy_level_needed': energyLevelNeeded,
      'is_enabled': isEnabled ? 1 : 0,
      'last_executed': lastExecuted?.toIso8601String(),
      'success_count': successCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HabitSchedule copyWith({
    int? id,
    int? habitId,
    int? scheduledHour,
    int? scheduledMinute,
    int? priority,
    int? energyLevelNeeded,
    bool? isEnabled,
    DateTime? lastExecuted,
    int? successCount,
    DateTime? createdAt,
  }) {
    return HabitSchedule(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      scheduledHour: scheduledHour ?? this.scheduledHour,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      priority: priority ?? this.priority,
      energyLevelNeeded: energyLevelNeeded ?? this.energyLevelNeeded,
      isEnabled: isEnabled ?? this.isEnabled,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      successCount: successCount ?? this.successCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ScheduleRecommendation {
  final int habitId;
  final String habitName;
  final int suggestedHour;
  final int suggestedMinute;
  final int? energyLevelNeeded;
  final double confidenceScore;
  final String reason;

  ScheduleRecommendation({
    required this.habitId,
    required this.habitName,
    required this.suggestedHour,
    required this.suggestedMinute,
    this.energyLevelNeeded,
    required this.confidenceScore,
    required this.reason,
  });
}

class HabitSchedulingStats {
  final int totalSchedules;
  final int activeSchedules;
  final double averageSuccessRate;
  final int optimalTimeCount;
  final List<ScheduleRecommendation> recommendations;

  HabitSchedulingStats({
    required this.totalSchedules,
    required this.activeSchedules,
    required this.averageSuccessRate,
    required this.optimalTimeCount,
    required this.recommendations,
  });
}