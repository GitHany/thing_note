class EmotionTrailData {
  final int? id;
  final String date;
  final int emotionLevel;
  final List<String> triggers;
  final List<String> events;
  final String? peakMoment;
  final String? lowMoment;
  final String? note;
  final DateTime createdAt;

  EmotionTrailData({
    this.id,
    required this.date,
    required this.emotionLevel,
    this.triggers = const [],
    this.events = const [],
    this.peakMoment,
    this.lowMoment,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'emotion_level': emotionLevel,
      'triggers': triggers.join(','),
      'events': events.join(','),
      'peak_moment': peakMoment,
      'low_moment': lowMoment,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EmotionTrailData.fromMap(Map<String, dynamic> map) {
    return EmotionTrailData(
      id: map['id'],
      date: map['date'],
      emotionLevel: map['emotion_level'],
      triggers: (map['triggers'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      events: (map['events'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      peakMoment: map['peak_moment'],
      lowMoment: map['low_moment'],
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  EmotionTrailData copyWith({
    int? id,
    String? date,
    int? emotionLevel,
    List<String>? triggers,
    List<String>? events,
    String? peakMoment,
    String? lowMoment,
    String? note,
    DateTime? createdAt,
  }) {
    return EmotionTrailData(
      id: id ?? this.id,
      date: date ?? this.date,
      emotionLevel: emotionLevel ?? this.emotionLevel,
      triggers: triggers ?? this.triggers,
      events: events ?? this.events,
      peakMoment: peakMoment ?? this.peakMoment,
      lowMoment: lowMoment ?? this.lowMoment,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}