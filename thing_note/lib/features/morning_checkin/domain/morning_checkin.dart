/// Morning Check-in 数据模型
class MorningCheckin {
  final int? id;
  final DateTime date;
  final int energyLevel; // 1-5
  final int moodLevel; // 1-5
  final String? intention;
  final String? focusArea;
  final List<String> priorities;
  final String? gratitudeNote;
  final DateTime createdAt;

  const MorningCheckin({
    this.id,
    required this.date,
    this.energyLevel = 3,
    this.moodLevel = 3,
    this.intention,
    this.focusArea,
    this.priorities = const [],
    this.gratitudeNote,
    required this.createdAt,
  });

  MorningCheckin copyWith({
    int? id,
    DateTime? date,
    int? energyLevel,
    int? moodLevel,
    String? intention,
    String? focusArea,
    List<String>? priorities,
    String? gratitudeNote,
    DateTime? createdAt,
  }) {
    return MorningCheckin(
      id: id ?? this.id,
      date: date ?? this.date,
      energyLevel: energyLevel ?? this.energyLevel,
      moodLevel: moodLevel ?? this.moodLevel,
      intention: intention ?? this.intention,
      focusArea: focusArea ?? this.focusArea,
      priorities: priorities ?? this.priorities,
      gratitudeNote: gratitudeNote ?? this.gratitudeNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'energy_level': energyLevel,
      'mood_level': moodLevel,
      'intention': intention,
      'focus_area': focusArea,
      'priorities': priorities.join(','),
      'gratitude_note': gratitudeNote,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MorningCheckin.fromMap(Map<String, dynamic> map) {
    return MorningCheckin(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      energyLevel: map['energy_level'] as int? ?? 3,
      moodLevel: map['mood_level'] as int? ?? 3,
      intention: map['intention'] as String?,
      focusArea: map['focus_area'] as String?,
      priorities: (map['priorities'] as String?)?.isNotEmpty == true
          ? (map['priorities'] as String).split(',')
          : [],
      gratitudeNote: map['gratitude_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 今日签到状态
enum CheckinStatus {
  notStarted,
  inProgress,
  completed,
}