/// 每日任务数据模型
class DailyTask {
  final int? id;
  final String title;
  final String date;
  final TaskPriority priority;
  final String? timeSlot;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final int? linkedRecordId;

  const DailyTask({
    this.id,
    required this.title,
    required this.date,
    this.priority = TaskPriority.medium,
    this.timeSlot,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.linkedRecordId,
  });

  DailyTask copyWith({
    int? id,
    String? title,
    String? date,
    TaskPriority? priority,
    String? timeSlot,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    int? linkedRecordId,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      timeSlot: timeSlot ?? this.timeSlot,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'date': date,
      'priority': priority.name,
      'time_slot': timeSlot,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'linked_record_id': linkedRecordId,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: map['date'] as String,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      timeSlot: map['time_slot'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      linkedRecordId: map['linked_record_id'] as int?,
    );
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }

  int get colorValue {
    switch (this) {
      case TaskPriority.low:
        return 0xFF4CAF50;
      case TaskPriority.medium:
        return 0xFF2196F3;
      case TaskPriority.high:
        return 0xFFFF9800;
      case TaskPriority.urgent:
        return 0xFFF44336;
    }
  }
}