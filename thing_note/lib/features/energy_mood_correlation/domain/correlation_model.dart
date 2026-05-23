class EnergyMoodCorrelation {
  final int id;
  final String date;
  final int? energyLevel;
  final int? moodLevel;
  final String? activityType;
  final double correlationScore;
  final DateTime createdAt;

  EnergyMoodCorrelation({
    required this.id,
    required this.date,
    this.energyLevel,
    this.moodLevel,
    this.activityType,
    this.correlationScore = 0,
    required this.createdAt,
  });

  factory EnergyMoodCorrelation.fromMap(Map<String, dynamic> map) {
    return EnergyMoodCorrelation(
      id: map['id'] as int,
      date: map['date'] as String,
      energyLevel: map['energy_level'] as int?,
      moodLevel: map['mood_level'] as int?,
      activityType: map['activity_type'] as String?,
      correlationScore: (map['correlation_score'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CorrelationInsight {
  final String factor;
  final String insight;
  final double confidence;
  final List<String> recommendations;

  CorrelationInsight({
    required this.factor,
    required this.insight,
    required this.confidence,
    required this.recommendations,
  });
}

class EnergyMoodStats {
  final double averageEnergy;
  final double averageMood;
  final double correlation;
  final String peakEnergyTime;
  final String bestMoodTime;
  final List<CorrelationInsight> insights;

  EnergyMoodStats({
    required this.averageEnergy,
    required this.averageMood,
    required this.correlation,
    required this.peakEnergyTime,
    required this.bestMoodTime,
    required this.insights,
  });
}