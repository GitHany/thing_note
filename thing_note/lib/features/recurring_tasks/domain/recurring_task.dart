class RecurringTask {
  final int? id;
  final String title;
  final String? description;
  final String repeatType;
  final int repeatInterval;
  final String? customDays;
  final int priority;
  final String? category;
  final int estimatedMinutes;
  final int completedCount;
  final int skippedCount;
  final int currentStreak;
  final int bestStreak;
  final String? lastCompletedAt;
  final String? nextDueAt;
  final int isActive;
  final int? linkedGoalId;
  final String createdAt;
  final String updatedAt;

  RecurringTask({
    this.id,
    required this.title,
    this.description,
    this.repeatType = 'daily',
    this.repeatInterval = 1,
    this.customDays,
    this.priority = 2,
    this.category,
    this.estimatedMinutes = 30,
    this.completedCount = 0,
    this.skippedCount = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedAt,
    this.nextDueAt,
    this.isActive = 1,
    this.linkedGoalId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'repeat_type': repeatType,
      'repeat_interval': repeatInterval,
      'custom_days': customDays,
      'priority': priority,
      'category': category,
      'estimated_minutes': estimatedMinutes,
      'completed_count': completedCount,
      'skipped_count': skippedCount,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_completed_at': lastCompletedAt,
      'next_due_at': nextDueAt,
      'is_active': isActive,
      'linked_goal_id': linkedGoalId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RecurringTask.fromMap(Map<String, dynamic> map) {
    return RecurringTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      repeatType: map['repeat_type'] as String? ?? 'daily',
      repeatInterval: map['repeat_interval'] as int? ?? 1,
      customDays: map['custom_days'] as String?,
      priority: map['priority'] as int? ?? 2,
      category: map['category'] as String?,
      estimatedMinutes: map['estimated_minutes'] as int? ?? 30,
      completedCount: map['completed_count'] as int? ?? 0,
      skippedCount: map['skipped_count'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      lastCompletedAt: map['last_completed_at'] as String?,
      nextDueAt: map['next_due_at'] as String?,
      isActive: map['is_active'] as int? ?? 1,
      linkedGoalId: map['linked_goal_id'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  RecurringTask copyWith({
    int? id,
    String? title,
    String? description,
    String? repeatType,
    int? repeatInterval,
    String? customDays,
    int? priority,
    String? category,
    int? estimatedMinutes,
    int? completedCount,
    int? skippedCount,
    int? currentStreak,
    int? bestStreak,
    String? lastCompletedAt,
    String? nextDueAt,
    int? isActive,
    int? linkedGoalId,
    String? createdAt,
    String? updatedAt,
  }) {
    return RecurringTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      customDays: customDays ?? this.customDays,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completedCount: completedCount ?? this.completedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      isActive: isActive ?? this.isActive,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get repeatTypeLabel {
    switch (repeatType) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      case 'custom':
        return '自定义';
      default:
        return repeatType;
    }
  }

  bool get isOverdue {
    if (nextDueAt == null) return false;
    final dueDate = DateTime.parse(nextDueAt!);
    return dueDate.isBefore(DateTime.now());
  }
}