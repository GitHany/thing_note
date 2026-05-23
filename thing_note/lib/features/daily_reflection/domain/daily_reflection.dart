class DailyReflection {
  final int? id;
  final String date;
  final String achievements;
  final String gratitude;
  final String improvements;
  final String tomorrowPriority;
  final int moodSummary;
  final String? reflectionTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyReflection({
    this.id,
    required this.date,
    this.achievements = '',
    this.gratitude = '',
    this.improvements = '',
    this.tomorrowPriority = '',
    this.moodSummary = 3,
    this.reflectionTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'achievements': achievements,
      'gratitude': gratitude,
      'improvements': improvements,
      'tomorrow_priority': tomorrowPriority,
      'mood_summary': moodSummary,
      'reflection_template': reflectionTemplate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyReflection.fromMap(Map<String, dynamic> map) {
    return DailyReflection(
      id: map['id'] as int?,
      date: map['date'] as String,
      achievements: map['achievements'] as String? ?? '',
      gratitude: map['gratitude'] as String? ?? '',
      improvements: map['improvements'] as String? ?? '',
      tomorrowPriority: map['tomorrow_priority'] as String? ?? '',
      moodSummary: map['mood_summary'] as int? ?? 3,
      reflectionTemplate: map['reflection_template'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  DailyReflection copyWith({
    int? id,
    String? date,
    String? achievements,
    String? gratitude,
    String? improvements,
    String? tomorrowPriority,
    int? moodSummary,
    String? reflectionTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReflection(
      id: id ?? this.id,
      date: date ?? this.date,
      achievements: achievements ?? this.achievements,
      gratitude: gratitude ?? this.gratitude,
      improvements: improvements ?? this.improvements,
      tomorrowPriority: tomorrowPriority ?? this.tomorrowPriority,
      moodSummary: moodSummary ?? this.moodSummary,
      reflectionTemplate: reflectionTemplate ?? this.reflectionTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}