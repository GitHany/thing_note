/// 月度里程碑数据模型
class MonthlyMilestone {
  final int? id;
  final int year;
  final int month;
  final String milestoneTitle;
  final String? description;
  final String? targetType; // count / duration / streak / custom
  final double targetValue;
  final double currentValue;
  final String? category;
  final bool isCompleted;
  final DateTime? completedAt;
  final int color;
  final DateTime createdAt;

  const MonthlyMilestone({
    this.id,
    required this.year,
    required this.month,
    required this.milestoneTitle,
    this.description,
    this.targetType,
    this.targetValue = 1,
    this.currentValue = 0,
    this.category,
    this.isCompleted = false,
    this.completedAt,
    this.color = 0xFF2196F3,
    required this.createdAt,
  });

  double get progressPercent =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isOverdue {
    final now = DateTime.now();
    return (year < now.year) || (year == now.year && month < now.month);
  }

  MonthlyMilestone copyWith({
    int? id,
    int? year,
    int? month,
    String? milestoneTitle,
    String? description,
    String? targetType,
    double? targetValue,
    double? currentValue,
    String? category,
    bool? isCompleted,
    DateTime? completedAt,
    int? color,
    DateTime? createdAt,
  }) {
    return MonthlyMilestone(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      milestoneTitle: milestoneTitle ?? this.milestoneTitle,
      description: description ?? this.description,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'year': year,
      'month': month,
      'milestone_title': milestoneTitle,
      'description': description,
      'target_type': targetType,
      'target_value': targetValue,
      'current_value': currentValue,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MonthlyMilestone.fromMap(Map<String, dynamic> map) {
    return MonthlyMilestone(
      id: map['id'] as int?,
      year: map['year'] as int,
      month: map['month'] as int,
      milestoneTitle: map['milestone_title'] as String,
      description: map['description'] as String?,
      targetType: map['target_type'] as String?,
      targetValue: (map['target_value'] as num?)?.toDouble() ?? 1,
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      color: map['color'] as int? ?? 0xFF2196F3,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class MilestoneProgress {
  final int? id;
  final int milestoneId;
  final String date;
  final double progress;
  final String? note;
  final DateTime createdAt;

  const MilestoneProgress({
    this.id,
    required this.milestoneId,
    required this.date,
    this.progress = 0,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'milestone_id': milestoneId,
      'date': date,
      'progress': progress,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MilestoneProgress.fromMap(Map<String, dynamic> map) {
    return MilestoneProgress(
      id: map['id'] as int?,
      milestoneId: map['milestone_id'] as int,
      date: map['date'] as String,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
