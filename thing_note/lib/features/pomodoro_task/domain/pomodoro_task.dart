/// Pomodoro 任务数据模型
class PomodoroTask {
  final int? id;
  final String title;
  final String? description;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final PomodoroStatus status;
  final PomodoroPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PomodoroSession> sessions;

  const PomodoroTask({
    this.id,
    required this.title,
    this.description,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.status = PomodoroStatus.pending,
    this.priority = PomodoroPriority.medium,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.sessions = const [],
  });

  double get progress =>
      estimatedPomodoros > 0 ? (completedPomodoros / estimatedPomodoros).clamp(0.0, 1.0) : 0.0;

  PomodoroTask copyWith({
    int? id,
    String? title,
    String? description,
    int? estimatedPomodoros,
    int? completedPomodoros,
    PomodoroStatus? status,
    PomodoroPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PomodoroSession>? sessions,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'estimated_pomodoros': estimatedPomodoros,
      'completed_pomodoros': completedPomodoros,
      'status': status.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PomodoroTask.fromMap(Map<String, dynamic> map) {
    return PomodoroTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      estimatedPomodoros: map['estimated_pomodoros'] as int? ?? 1,
      completedPomodoros: map['completed_pomodoros'] as int? ?? 0,
      status: PomodoroStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PomodoroStatus.pending,
      ),
      priority: PomodoroPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => PomodoroPriority.medium,
      ),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Pomodoro 会话
class PomodoroSession {
  final int? id;
  final int taskId;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int focusScore; // 1-5
  final String? note;

  const PomodoroSession({
    this.id,
    required this.taskId,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
    this.focusScore = 3,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'duration_minutes': durationMinutes,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'focus_score': focusScore,
      'note': note,
    };
  }

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      durationMinutes: map['duration_minutes'] as int? ?? 25,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      focusScore: map['focus_score'] as int? ?? 3,
      note: map['note'] as String?,
    );
  }
}

enum PomodoroStatus { pending, inProgress, completed, paused }
enum PomodoroPriority { low, medium, high, urgent }

extension PomodoroStatusExtension on PomodoroStatus {
  String get displayName {
    switch (this) {
      case PomodoroStatus.pending:
        return '待办';
      case PomodoroStatus.inProgress:
        return '进行中';
      case PomodoroStatus.completed:
        return '已完成';
      case PomodoroStatus.paused:
        return '已暂停';
    }
  }
}

extension PomodoroPriorityExtension on PomodoroPriority {
  String get displayName {
    switch (this) {
      case PomodoroPriority.low:
        return '低';
      case PomodoroPriority.medium:
        return '中';
      case PomodoroPriority.high:
        return '高';
      case PomodoroPriority.urgent:
        return '紧急';
    }
  }
}