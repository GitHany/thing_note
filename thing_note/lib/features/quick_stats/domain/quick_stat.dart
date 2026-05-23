class QuickStat {
  final int? id;
  final String date;
  final int recordCount;
  final int totalDurationMinutes;
  final String? topThingName;
  final String? topTag;
  final int completedHabits;
  final double? moodScore;
  final int? energyLevel;
  final DateTime createdAt;

  QuickStat({
    this.id,
    required this.date,
    this.recordCount = 0,
    this.totalDurationMinutes = 0,
    this.topThingName,
    this.topTag,
    this.completedHabits = 0,
    this.moodScore,
    this.energyLevel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'record_count': recordCount,
      'total_duration_minutes': totalDurationMinutes,
      'top_thing_name': topThingName,
      'top_tag': topTag,
      'completed_habits': completedHabits,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickStat.fromMap(Map<String, dynamic> map) {
    return QuickStat(
      id: map['id'] as int?,
      date: map['date'] as String,
      recordCount: map['record_count'] as int? ?? 0,
      totalDurationMinutes: map['total_duration_minutes'] as int? ?? 0,
      topThingName: map['top_thing_name'] as String?,
      topTag: map['top_tag'] as String?,
      completedHabits: map['completed_habits'] as int? ?? 0,
      moodScore: map['mood_score'] as double?,
      energyLevel: map['energy_level'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}