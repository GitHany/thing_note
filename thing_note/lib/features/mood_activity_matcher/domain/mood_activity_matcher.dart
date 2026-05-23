/// Mood Activity Matcher 数据模型
class MoodActivityMapping {
  final int? id;
  final String activity;
  final int avgMood;
  final int sampleCount;
  final DateTime lastUpdated;

  const MoodActivityMapping({
    this.id,
    required this.activity,
    this.avgMood = 3,
    this.sampleCount = 0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activity': activity,
      'avg_mood': avgMood,
      'sample_count': sampleCount,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory MoodActivityMapping.fromMap(Map<String, dynamic> map) {
    return MoodActivityMapping(
      id: map['id'] as int?,
      activity: map['activity'] as String,
      avgMood: map['avg_mood'] as int? ?? 3,
      sampleCount: map['sample_count'] as int? ?? 0,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }
}

/// 活动推荐
class ActivityRecommendation {
  final String activity;
  final double confidence;
  final String reason;

  const ActivityRecommendation({
    required this.activity,
    required this.confidence,
    required this.reason,
  });
}