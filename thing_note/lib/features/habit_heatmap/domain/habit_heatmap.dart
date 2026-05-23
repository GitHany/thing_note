/// 习惯热力图数据模型
class HabitHeatmapData {
  final int? id;
  final int habitId;
  final String date;
  final int completionLevel; // 0-4: 无记录/部分/完成/超额/完美
  final DateTime createdAt;

  const HabitHeatmapData({
    this.id,
    required this.habitId,
    required this.date,
    this.completionLevel = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'date': date,
      'completion_level': completionLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitHeatmapData.fromMap(Map<String, dynamic> map) {
    return HabitHeatmapData(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: map['date'] as String,
      completionLevel: map['completion_level'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 热力图统计数据
class HeatmapStats {
  final int totalDays;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> weekdayDistribution;

  const HeatmapStats({
    this.totalDays = 0,
    this.activeDays = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weekdayDistribution = const {},
  });

  double get completionRate =>
      totalDays > 0 ? (activeDays / totalDays) : 0.0;
}
