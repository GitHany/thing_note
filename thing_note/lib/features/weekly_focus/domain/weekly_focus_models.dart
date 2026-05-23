// Weekly Focus feature
// Version: 1.0
// Description: 周主题设定，每周设置一个主要关注点，围绕它安排任务和活动

class WeeklyFocus {
  final int? id;
  final int weekNumber;
  final int year;
  final String title;
  final String? description;
  final String? theme; // 工作/健康/学习/社交等
  final int color;
  final String status; // planning, active, completed
  final String? createdAt;
  final String? updatedAt;

  WeeklyFocus({
    this.id,
    required this.weekNumber,
    required this.year,
    required this.title,
    this.description,
    this.theme,
    this.color = 0xFF2196F3,
    this.status = 'planning',
    this.createdAt,
    this.updatedAt,
  });

  factory WeeklyFocus.fromMap(Map<String, dynamic> map) {
    return WeeklyFocus(
      id: map['id'] as int?,
      weekNumber: map['week_number'] as int,
      year: map['year'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      theme: map['theme'] as String?,
      color: map['color'] as int? ?? 0xFF2196F3,
      status: map['status'] as String? ?? 'planning',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week_number': weekNumber,
      'year': year,
      'title': title,
      'description': description,
      'theme': theme,
      'color': color,
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  WeeklyFocus copyWith({
    int? id,
    int? weekNumber,
    int? year,
    String? title,
    String? description,
    String? theme,
    int? color,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return WeeklyFocus(
      id: id ?? this.id,
      weekNumber: weekNumber ?? this.weekNumber,
      year: year ?? this.year,
      title: title ?? this.title,
      description: description ?? this.description,
      theme: theme ?? this.theme,
      color: color ?? this.color,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WeeklyGoal {
  final int? id;
  final int focusId;
  final String title;
  final int progress; // 0-100
  final bool isCompleted;
  final int sortOrder;
  final String? createdAt;

  WeeklyGoal({
    this.id,
    required this.focusId,
    required this.title,
    this.progress = 0,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory WeeklyGoal.fromMap(Map<String, dynamic> map) {
    return WeeklyGoal(
      id: map['id'] as int?,
      focusId: map['focus_id'] as int,
      title: map['title'] as String,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'focus_id': focusId,
      'title': title,
      'progress': progress,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class WeeklyFocusWithGoals {
  final WeeklyFocus focus;
  final List<WeeklyGoal> goals;

  WeeklyFocusWithGoals({
    required this.focus,
    required this.goals,
  });

  double get overallProgress {
    if (goals.isEmpty) return 0;
    return goals.map((g) => g.progress).reduce((a, b) => a + b) / goals.length;
  }
}