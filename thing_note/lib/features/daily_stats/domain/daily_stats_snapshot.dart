/// 每日统计快照数据模型
class DailyStatsSnapshot {
  final int? id;
  final String date;
  final int recordsCount;
  final int totalDurationMinutes;
  final int habitsCompleted;
  final int habitsTotal;
  final int goalsCompleted;
  final int? moodScore;
  final int? energyScore;
  final String? topThingNames;
  final String? topTags;
  final String? notes;
  final DateTime createdAt;

  const DailyStatsSnapshot({
    this.id,
    required this.date,
    this.recordsCount = 0,
    this.totalDurationMinutes = 0,
    this.habitsCompleted = 0,
    this.habitsTotal = 0,
    this.goalsCompleted = 0,
    this.moodScore,
    this.energyScore,
    this.topThingNames,
    this.topTags,
    this.notes,
    required this.createdAt,
  });

  double get habitsCompletionRate =>
      habitsTotal > 0 ? (habitsCompleted / habitsTotal) : 0.0;

  DailyStatsSnapshot copyWith({
    int? id,
    String? date,
    int? recordsCount,
    int? totalDurationMinutes,
    int? habitsCompleted,
    int? habitsTotal,
    int? goalsCompleted,
    int? moodScore,
    int? energyScore,
    String? topThingNames,
    String? topTags,
    String? notes,
    DateTime? createdAt,
  }) {
    return DailyStatsSnapshot(
      id: id ?? this.id,
      date: date ?? this.date,
      recordsCount: recordsCount ?? this.recordsCount,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      habitsTotal: habitsTotal ?? this.habitsTotal,
      goalsCompleted: goalsCompleted ?? this.goalsCompleted,
      moodScore: moodScore ?? this.moodScore,
      energyScore: energyScore ?? this.energyScore,
      topThingNames: topThingNames ?? this.topThingNames,
      topTags: topTags ?? this.topTags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'records_count': recordsCount,
      'total_duration_minutes': totalDurationMinutes,
      'habits_completed': habitsCompleted,
      'habits_total': habitsTotal,
      'goals_completed': goalsCompleted,
      'mood_score': moodScore,
      'energy_score': energyScore,
      'top_thing_names': topThingNames,
      'top_tags': topTags,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyStatsSnapshot.fromMap(Map<String, dynamic> map) {
    return DailyStatsSnapshot(
      id: map['id'] as int?,
      date: map['date'] as String,
      recordsCount: map['records_count'] as int? ?? 0,
      totalDurationMinutes: map['total_duration_minutes'] as int? ?? 0,
      habitsCompleted: map['habits_completed'] as int? ?? 0,
      habitsTotal: map['habits_total'] as int? ?? 0,
      goalsCompleted: map['goals_completed'] as int? ?? 0,
      moodScore: map['mood_score'] as int?,
      energyScore: map['energy_score'] as int?,
      topThingNames: map['top_thing_names'] as String?,
      topTags: map['top_tags'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
