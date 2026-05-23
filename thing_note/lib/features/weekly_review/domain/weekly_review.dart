/// 周回顾数据模型
class WeeklyReview {
  final int? id;
  final String weekStartDate;
  final String weekEndDate;
  final String? highlights;
  final String? reflections;
  final String? accomplishments;
  final String? nextWeekGoals;
  final DateTime createdAt;

  const WeeklyReview({
    this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    this.highlights,
    this.reflections,
    this.accomplishments,
    this.nextWeekGoals,
    required this.createdAt,
  });

  WeeklyReview copyWith({
    int? id,
    String? weekStartDate,
    String? weekEndDate,
    String? highlights,
    String? reflections,
    String? accomplishments,
    String? nextWeekGoals,
    DateTime? createdAt,
  }) {
    return WeeklyReview(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      highlights: highlights ?? this.highlights,
      reflections: reflections ?? this.reflections,
      accomplishments: accomplishments ?? this.accomplishments,
      nextWeekGoals: nextWeekGoals ?? this.nextWeekGoals,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'week_start_date': weekStartDate,
      'week_end_date': weekEndDate,
      'highlights': highlights,
      'reflections': reflections,
      'accomplishments': accomplishments,
      'next_week_goals': nextWeekGoals,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReview.fromMap(Map<String, dynamic> map) {
    return WeeklyReview(
      id: map['id'] as int?,
      weekStartDate: map['week_start_date'] as String,
      weekEndDate: map['week_end_date'] as String,
      highlights: map['highlights'] as String?,
      reflections: map['reflections'] as String?,
      accomplishments: map['accomplishments'] as String?,
      nextWeekGoals: map['next_week_goals'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get displayRange => '$weekStartDate ~ $weekEndDate';
}

/// 周数据统计
class WeekStats {
  final int recordCount;
  final int totalMinutes;
  final int completedGoals;
  final int completedHabits;
  final Map<String, int> topActivities;
  final double moodAverage;

  const WeekStats({
    this.recordCount = 0,
    this.totalMinutes = 0,
    this.completedGoals = 0,
    this.completedHabits = 0,
    this.topActivities = const {},
    this.moodAverage = 0,
  });
}