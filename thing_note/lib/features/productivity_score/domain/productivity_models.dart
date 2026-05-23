class DailyProductivityScore {
  final int? id;
  final DateTime date;
  final int focusScore;
  final int energyScore;
  final int outputScore;
  final double overallScore;
  final int completedTasks;
  final int plannedTasks;
  final int deepWorkMinutes;
  final int interruptionCount;
  final int? moodAtStart;
  final int? moodAtEnd;
  final String? notes;
  final DateTime createdAt;

  DailyProductivityScore({
    this.id,
    required this.date,
    this.focusScore = 0,
    this.energyScore = 0,
    this.outputScore = 0,
    this.overallScore = 0,
    this.completedTasks = 0,
    this.plannedTasks = 0,
    this.deepWorkMinutes = 0,
    this.interruptionCount = 0,
    this.moodAtStart,
    this.moodAtEnd,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().split('T')[0],
      'focus_score': focusScore,
      'energy_score': energyScore,
      'output_score': outputScore,
      'overall_score': overallScore,
      'completed_tasks': completedTasks,
      'planned_tasks': plannedTasks,
      'deep_work_minutes': deepWorkMinutes,
      'interruption_count': interruptionCount,
      'mood_at_start': moodAtStart,
      'mood_at_end': moodAtEnd,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyProductivityScore.fromMap(Map<String, dynamic> map) {
    return DailyProductivityScore(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      focusScore: map['focus_score'] as int? ?? 0,
      energyScore: map['energy_score'] as int? ?? 0,
      outputScore: map['output_score'] as int? ?? 0,
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0,
      completedTasks: map['completed_tasks'] as int? ?? 0,
      plannedTasks: map['planned_tasks'] as int? ?? 0,
      deepWorkMinutes: map['deep_work_minutes'] as int? ?? 0,
      interruptionCount: map['interruption_count'] as int? ?? 0,
      moodAtStart: map['mood_at_start'] as int?,
      moodAtEnd: map['mood_at_end'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}