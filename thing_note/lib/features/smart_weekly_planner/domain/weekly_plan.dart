class WeeklyPlan {
  final int? id;
  final String title;
  final String? description;
  final int dayOfWeek; // 1-7 (周一到周日)
  final String? timeSlot;
  final String priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? linkedGoalId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WeeklyPlan({
    this.id,
    required this.title,
    this.description,
    required this.dayOfWeek,
    this.timeSlot,
    this.priority = 'medium',
    this.isCompleted = false,
    this.completedAt,
    this.linkedGoalId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'day_of_week': dayOfWeek,
      'time_slot': timeSlot,
      'priority': priority,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'linked_goal_id': linkedGoalId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) {
    return WeeklyPlan(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      timeSlot: map['time_slot'] as String?,
      priority: map['priority'] as String? ?? 'medium',
      isCompleted: (map['is_completed'] as int?) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      linkedGoalId: map['linked_goal_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  WeeklyPlan copyWith({
    int? id,
    String? title,
    String? description,
    int? dayOfWeek,
    String? timeSlot,
    String? priority,
    bool? isCompleted,
    DateTime? completedAt,
    int? linkedGoalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}