/// Mood Correlation Entry model
class MoodCorrelationEntry {
  final int? id;
  final DateTime date;
  final String activity;
  final int moodScore;
  final int energyLevel;
  final String? note;
  final List<String> tags;
  final DateTime createdAt;

  MoodCorrelationEntry({
    this.id,
    required this.date,
    required this.activity,
    required this.moodScore,
    this.energyLevel = 3,
    this.note,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'activity': activity,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      'note': note,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodCorrelationEntry.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return MoodCorrelationEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      activity: map['activity'] as String,
      moodScore: map['mood_score'] as int,
      energyLevel: map['energy_level'] as int? ?? 3,
      note: map['note'] as String?,
      tags: tagsStr != null && tagsStr.isNotEmpty 
          ? tagsStr.split(',') 
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Activity Mood Impact model
class ActivityMoodImpact {
  final String activity;
  final double avgMoodScore;
  final double avgEnergyLevel;
  final int sampleCount;
  final double moodImpactScore;
  final bool isPositive;

  ActivityMoodImpact({
    required this.activity,
    required this.avgMoodScore,
    required this.avgEnergyLevel,
    required this.sampleCount,
    required this.moodImpactScore,
    required this.isPositive,
  });

  factory ActivityMoodImpact.empty(String activity) {
    return ActivityMoodImpact(
      activity: activity,
      avgMoodScore: 0,
      avgEnergyLevel: 0,
      sampleCount: 0,
      moodImpactScore: 0,
      isPositive: false,
    );
  }
}

/// Mood Correlation Statistics
class MoodCorrelationStats {
  final int totalEntries;
  final double averageMood;
  final double averageEnergy;
  final String bestActivity;
  final String worstActivity;
  final List<ActivityMoodImpact> topPositiveActivities;
  final List<ActivityMoodImpact> topNegativeActivities;
  final Map<String, double> weeklyMoodTrend;

  MoodCorrelationStats({
    required this.totalEntries,
    required this.averageMood,
    required this.averageEnergy,
    required this.bestActivity,
    required this.worstActivity,
    required this.topPositiveActivities,
    required this.topNegativeActivities,
    required this.weeklyMoodTrend,
  });

  factory MoodCorrelationStats.empty() {
    return MoodCorrelationStats(
      totalEntries: 0,
      averageMood: 0,
      averageEnergy: 0,
      bestActivity: '',
      worstActivity: '',
      topPositiveActivities: [],
      topNegativeActivities: [],
      weeklyMoodTrend: {},
    );
  }
}