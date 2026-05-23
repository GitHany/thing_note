// Mini Tasks feature
// Version: 1.0
// Description: 微任务管理，将大任务分解为可执行的小步骤

class MiniTask {
  final int? id;
  final String title;
  final String? description;
  final int? parentTaskId;
  final int priority; // 1=低, 2=中, 3=高, 4=紧急
  final int estimatedMinutes;
  final int actualMinutes;
  final bool isCompleted;
  final String? dueDate;
  final String? completedAt;
  final String status; // pending, in_progress, completed, cancelled
  final int sortOrder;
  final String? createdAt;

  MiniTask({
    this.id,
    required this.title,
    this.description,
    this.parentTaskId,
    this.priority = 2,
    this.estimatedMinutes = 15,
    this.actualMinutes = 0,
    this.isCompleted = false,
    this.dueDate,
    this.completedAt,
    this.status = 'pending',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory MiniTask.fromMap(Map<String, dynamic> map) {
    return MiniTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      parentTaskId: map['parent_task_id'] as int?,
      priority: map['priority'] as int? ?? 2,
      estimatedMinutes: map['estimated_minutes'] as int? ?? 15,
      actualMinutes: map['actual_minutes'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      dueDate: map['due_date'] as String?,
      completedAt: map['completed_at'] as String?,
      status: map['status'] as String? ?? 'pending',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'parent_task_id': parentTaskId,
      'priority': priority,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'is_completed': isCompleted ? 1 : 0,
      'due_date': dueDate,
      'completed_at': completedAt,
      'status': status,
      'sort_order': sortOrder,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  MiniTask copyWith({
    int? id,
    String? title,
    String? description,
    int? parentTaskId,
    int? priority,
    int? estimatedMinutes,
    int? actualMinutes,
    bool? isCompleted,
    String? dueDate,
    String? completedAt,
    String? status,
    int? sortOrder,
    String? createdAt,
  }) {
    return MiniTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TaskGroup {
  final int? id;
  final String title;
  final String? description;
  final int color;
  final double progress;
  final String? createdAt;

  TaskGroup({
    this.id,
    required this.title,
    this.description,
    this.color = 0xFF2196F3,
    this.progress = 0,
    this.createdAt,
  });

  factory TaskGroup.fromMap(Map<String, dynamic> map) {
    return TaskGroup(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      color: map['color'] as int? ?? 0xFF2196F3,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'color': color,
      'progress': progress,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}