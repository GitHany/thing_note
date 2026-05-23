/// 情绪-活动关联数据模型
class MoodActivityCorrelation {
  final int? id;
  final String activityName;
  final double avgMoodScore;
  final int sampleCount;
  final double correlationStrength;
  final DateTime? lastCalculated;
  final DateTime createdAt;

  MoodActivityCorrelation({
    this.id,
    required this.activityName,
    this.avgMoodScore = 0.0,
    this.sampleCount = 0,
    this.correlationStrength = 0.0,
    this.lastCalculated,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_name': activityName,
      'avg_mood_score': avgMoodScore,
      'sample_count': sampleCount,
      'correlation_strength': correlationStrength,
      'last_calculated': lastCalculated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodActivityCorrelation.fromMap(Map<String, dynamic> map) {
    return MoodActivityCorrelation(
      id: map['id'] as int?,
      activityName: map['activity_name'] as String,
      avgMoodScore: (map['avg_mood_score'] as num?)?.toDouble() ?? 0.0,
      sampleCount: map['sample_count'] as int? ?? 0,
      correlationStrength: (map['correlation_strength'] as num?)?.toDouble() ?? 0.0,
      lastCalculated: map['last_calculated'] != null
          ? DateTime.parse(map['last_calculated'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MoodActivityCorrelation copyWith({
    int? id,
    String? activityName,
    double? avgMoodScore,
    int? sampleCount,
    double? correlationStrength,
    DateTime? lastCalculated,
    DateTime? createdAt,
  }) {
    return MoodActivityCorrelation(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      avgMoodScore: avgMoodScore ?? this.avgMoodScore,
      sampleCount: sampleCount ?? this.sampleCount,
      correlationStrength: correlationStrength ?? this.correlationStrength,
      lastCalculated: lastCalculated ?? this.lastCalculated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get moodEmoji {
    if (avgMoodScore >= 4.5) return '😊';
    if (avgMoodScore >= 3.5) return '🙂';
    if (avgMoodScore >= 2.5) return '😐';
    if (avgMoodScore >= 1.5) return '😔';
    return '😢';
  }
}

/// 活动洞察数据模型
class ActivityInsight {
  final int? id;
  final String insightType; // positive_trigger, negative_trigger, recommendation
  final String title;
  final String? description;
  final double confidenceScore;
  final DateTime generatedAt;

  ActivityInsight({
    this.id,
    required this.insightType,
    required this.title,
    this.description,
    this.confidenceScore = 0.0,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'insight_type': insightType,
      'title': title,
      'description': description,
      'confidence_score': confidenceScore,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory ActivityInsight.fromMap(Map<String, dynamic> map) {
    return ActivityInsight(
      id: map['id'] as int?,
      insightType: map['insight_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0.0,
      generatedAt: DateTime.parse(map['generated_at'] as String),
    );
  }

  String get insightIcon {
    switch (insightType) {
      case 'positive_trigger':
        return '💡';
      case 'negative_trigger':
        return '⚠️';
      case 'recommendation':
        return '🎯';
      default:
        return '📊';
    }
  }
}

/// 情绪-活动矩阵数据
class MoodActivityMatrix {
  final List<String> activities;
  final List<int> energyLevels;
  final List<List<double>> correlationMatrix;

  MoodActivityMatrix({
    required this.activities,
    required this.energyLevels,
    required this.correlationMatrix,
  });

  int get rows => activities.length;
  int get cols => energyLevels.length;

  double getValue(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return 0.0;
    return correlationMatrix[row][col];
  }
}

/// 周度关联趋势数据
class WeeklyCorrelationTrend {
  final DateTime weekStart;
  final double avgCorrelation;
  final int totalSamples;
  final List<String> topPositiveActivities;
  final List<String> topNegativeActivities;

  WeeklyCorrelationTrend({
    required this.weekStart,
    required this.avgCorrelation,
    required this.totalSamples,
    required this.topPositiveActivities,
    required this.topNegativeActivities,
  });
}