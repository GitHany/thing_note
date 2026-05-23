/// Daily summary model
class DailySummary {
  final int? id;
  final DateTime date;
  final int recordCount;
  final int totalDurationMinutes;
  final String? topThingName;
  final String? topTag;
  final int completedGoals;
  final double? moodScore;
  final DateTime createdAt;

  DailySummary({
    this.id,
    required this.date,
    this.recordCount = 0,
    this.totalDurationMinutes = 0,
    this.topThingName,
    this.topTag,
    this.completedGoals = 0,
    this.moodScore,
    required this.createdAt,
  });

  DailySummary copyWith({
    int? id,
    DateTime? date,
    int? recordCount,
    int? totalDurationMinutes,
    String? topThingName,
    String? topTag,
    int? completedGoals,
    double? moodScore,
    DateTime? createdAt,
  }) {
    return DailySummary(
      id: id ?? this.id,
      date: date ?? this.date,
      recordCount: recordCount ?? this.recordCount,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      topThingName: topThingName ?? this.topThingName,
      topTag: topTag ?? this.topTag,
      completedGoals: completedGoals ?? this.completedGoals,
      moodScore: moodScore ?? this.moodScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': _formatDate(date),
      'record_count': recordCount,
      'total_duration_minutes': totalDurationMinutes,
      'top_thing_name': topThingName,
      'top_tag': topTag,
      'completed_goals': completedGoals,
      'mood_score': moodScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      recordCount: map['record_count'] as int? ?? 0,
      totalDurationMinutes: map['total_duration_minutes'] as int? ?? 0,
      topThingName: map['top_thing_name'] as String?,
      topTag: map['top_tag'] as String?,
      completedGoals: map['completed_goals'] as int? ?? 0,
      moodScore: (map['mood_score'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}