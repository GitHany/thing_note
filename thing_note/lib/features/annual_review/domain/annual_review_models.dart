/// 年度回顾数据模型
class AnnualReview {
  final int? id;
  final int year;
  final int totalRecords;
  final int totalMinutes;
  final List<String> topActivities;
  final double habitCompletionRate;
  final double? avgMoodScore;
  final String? highlights;
  final String? achievements;
  final String? nextYearGoals;
  final DateTime createdAt;

  AnnualReview({
    this.id,
    required this.year,
    this.totalRecords = 0,
    this.totalMinutes = 0,
    this.topActivities = const [],
    this.habitCompletionRate = 0.0,
    this.avgMoodScore,
    this.highlights,
    this.achievements,
    this.nextYearGoals,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'total_records': totalRecords,
      'total_minutes': totalMinutes,
      'top_activities': topActivities.join(','),
      'habit_completion_rate': habitCompletionRate,
      'avg_mood_score': avgMoodScore,
      'highlights': highlights,
      'achievements': achievements,
      'next_year_goals': nextYearGoals,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AnnualReview.fromMap(Map<String, dynamic> map) {
    final topActivitiesStr = map['top_activities'] as String? ?? '';
    return AnnualReview(
      id: map['id'] as int?,
      year: map['year'] as int,
      totalRecords: map['total_records'] as int? ?? 0,
      totalMinutes: map['total_minutes'] as int? ?? 0,
      topActivities: topActivitiesStr.isEmpty ? [] : topActivitiesStr.split(','),
      habitCompletionRate: (map['habit_completion_rate'] as num?)?.toDouble() ?? 0.0,
      avgMoodScore: (map['avg_mood_score'] as num?)?.toDouble(),
      highlights: map['highlights'] as String?,
      achievements: map['achievements'] as String?,
      nextYearGoals: map['next_year_goals'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final days = hours ~/ 24;
    if (days > 0) {
      return '$days天${hours % 24}小时';
    }
    return '$hours小时';
  }
}

/// 年度目标数据模型
class YearlyGoal {
  final int? id;
  final int year;
  final String title;
  final String? description;
  final double? targetValue;
  final double currentValue;
  final bool isCompleted;
  final DateTime createdAt;

  YearlyGoal({
    this.id,
    required this.year,
    required this.title,
    this.description,
    this.targetValue,
    this.currentValue = 0.0,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => targetValue != null && targetValue! > 0 
      ? (currentValue / targetValue!).clamp(0.0, 1.0) 
      : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory YearlyGoal.fromMap(Map<String, dynamic> map) {
    return YearlyGoal(
      id: map['id'] as int?,
      year: map['year'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetValue: (map['target_value'] as num?)?.toDouble(),
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 年度统计数据
class AnnualStatistics {
  final int totalRecords;
  final int totalMinutes;
  final int activeDays;
  final double habitCompletionRate;
  final double avgMoodScore;
  final int streakDays;
  final int goalsCompleted;
  final int goalsTotal;
  final List<TopActivity> topActivities;
  final List<MonthlyData> monthlyData;

  AnnualStatistics({
    required this.totalRecords,
    required this.totalMinutes,
    required this.activeDays,
    required this.habitCompletionRate,
    required this.avgMoodScore,
    required this.streakDays,
    required this.goalsCompleted,
    required this.goalsTotal,
    required this.topActivities,
    required this.monthlyData,
  });

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final days = hours ~/ 24;
    if (days > 0) {
      return '$days天${hours % 24}小时';
    }
    return '$hours小时';
  }
}

/// Top 活动
class TopActivity {
  final String name;
  final int minutes;
  final int count;

  TopActivity({
    required this.name,
    required this.minutes,
    required this.count,
  });
}

/// 月度数据
class MonthlyData {
  final int month;
  final int recordCount;
  final int minutes;
  final double? moodScore;

  MonthlyData({
    required this.month,
    required this.recordCount,
    required this.minutes,
    this.moodScore,
  });
}