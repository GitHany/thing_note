/// 月度回顾模型
class MonthlyReview {
  final int? id;
  final int year;
  final int month;
  final String? highlights;
  final String? improvements;
  final String? reflection;
  final String? nextMonthGoals;
  final String? achievements;
  final double? overallScore;
  final DateTime createdAt;

  MonthlyReview({
    this.id,
    required this.year,
    required this.month,
    this.highlights,
    this.improvements,
    this.reflection,
    this.nextMonthGoals,
    this.achievements,
    this.overallScore,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'year': year,
      'month': month,
      'highlights': highlights,
      'improvements': improvements,
      'reflection': reflection,
      'next_month_goals': nextMonthGoals,
      'achievements': achievements,
      'overall_score': overallScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MonthlyReview.fromMap(Map<String, dynamic> map) {
    return MonthlyReview(
      id: map['id'] as int?,
      year: map['year'] as int,
      month: map['month'] as int,
      highlights: map['highlights'] as String?,
      improvements: map['improvements'] as String?,
      reflection: map['reflection'] as String?,
      nextMonthGoals: map['next_month_goals'] as String?,
      achievements: map['achievements'] as String?,
      overallScore: map['overall_score'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MonthlyReview copyWith({
    int? id,
    int? year,
    int? month,
    String? highlights,
    String? improvements,
    String? reflection,
    String? nextMonthGoals,
    String? achievements,
    double? overallScore,
    DateTime? createdAt,
  }) {
    return MonthlyReview(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      highlights: highlights ?? this.highlights,
      improvements: improvements ?? this.improvements,
      reflection: reflection ?? this.reflection,
      nextMonthGoals: nextMonthGoals ?? this.nextMonthGoals,
      achievements: achievements ?? this.achievements,
      overallScore: overallScore ?? this.overallScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 月度目标
class MonthlyGoal {
  final int? id;
  final int month;
  final int year;
  final String title;
  final String? description;
  final double? targetValue;
  final double currentValue;
  final bool isCompleted;
  final DateTime createdAt;

  MonthlyGoal({
    this.id,
    required this.month,
    required this.year,
    required this.title,
    this.description,
    this.targetValue,
    this.currentValue = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'month': month,
      'year': year,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MonthlyGoal.fromMap(Map<String, dynamic> map) {
    return MonthlyGoal(
      id: map['id'] as int?,
      month: map['month'] as int,
      year: map['year'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetValue: map['target_value'] as double?,
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  double get progress {
    if (targetValue == null || targetValue == 0) return 0;
    return (currentValue / targetValue!).clamp(0.0, 1.0);
  }
}