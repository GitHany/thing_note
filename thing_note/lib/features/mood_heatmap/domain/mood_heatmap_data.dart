class MoodHeatmapData {
  final int? id;
  final int year;
  final int month;
  final int day;
  final int moodLevel;
  final double intensity;
  final DateTime createdAt;

  MoodHeatmapData({
    this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.moodLevel,
    this.intensity = 1.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get dateString => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'year': year,
      'month': month,
      'day': day,
      'mood_level': moodLevel,
      'intensity': intensity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodHeatmapData.fromMap(Map<String, dynamic> map) {
    return MoodHeatmapData(
      id: map['id'] as int?,
      year: map['year'] as int,
      month: map['month'] as int,
      day: map['day'] as int,
      moodLevel: map['mood_level'] as int,
      intensity: (map['intensity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}