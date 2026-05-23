/// 目标追踪数据模型
class Goal {
  final int? id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final GoalStatus status;
  final GoalPriority priority;
  final int? linkedRecordId;
  final int currentProgress;
  final int targetProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    this.id,
    required this.title,
    this.description,
    this.deadline,
    this.status = GoalStatus.active,
    this.priority = GoalPriority.medium,
    this.linkedRecordId,
    this.currentProgress = 0,
    this.targetProgress = 100,
    required this.createdAt,
    required this.updatedAt,
  });

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    GoalStatus? status,
    GoalPriority? priority,
    int? linkedRecordId,
    int? currentProgress,
    int? targetProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progressPercent =>
      targetProgress > 0 ? (currentProgress / targetProgress).clamp(0.0, 1.0) : 0.0;

  bool get isOverdue =>
      deadline != null && deadline!.isBefore(DateTime.now()) && status != GoalStatus.completed;

  bool get isCompleted => status == GoalStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'linked_record_id': linkedRecordId,
      'current_progress': currentProgress,
      'target_progress': targetProgress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GoalStatus.active,
      ),
      priority: GoalPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => GoalPriority.medium,
      ),
      linkedRecordId: map['linked_record_id'] as int?,
      currentProgress: map['current_progress'] as int? ?? 0,
      targetProgress: map['target_progress'] as int? ?? 100,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum GoalStatus { active, paused, completed, cancelled }

enum GoalPriority { low, medium, high, critical }

extension GoalStatusExtension on GoalStatus {
  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return '进行中';
      case GoalStatus.paused:
        return '已暂停';
      case GoalStatus.completed:
        return '已完成';
      case GoalStatus.cancelled:
        return '已取消';
    }
  }
}

extension GoalPriorityExtension on GoalPriority {
  String get displayName {
    switch (this) {
      case GoalPriority.low:
        return '低';
      case GoalPriority.medium:
        return '中';
      case GoalPriority.high:
        return '高';
      case GoalPriority.critical:
        return '紧急';
    }
  }
}