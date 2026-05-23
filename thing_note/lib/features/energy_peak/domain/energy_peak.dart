/// Energy Peak 数据模型
class EnergyPeak {
  final int? id;
  final DateTime date;
  final int hour;
  final int energyLevel; // 1-10
  final String? activity;
  final String? note;
  final DateTime createdAt;

  const EnergyPeak({
    this.id,
    required this.date,
    required this.hour,
    required this.energyLevel,
    this.activity,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'hour': hour,
      'energy_level': energyLevel,
      'activity': activity,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EnergyPeak.fromMap(Map<String, dynamic> map) {
    return EnergyPeak(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      hour: map['hour'] as int,
      energyLevel: map['energy_level'] as int,
      activity: map['activity'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 能量峰值统计
class EnergyStats {
  final Map<int, double> hourlyAverage; // hour -> average energy
  final int? bestHour;
  final int? worstHour;
  final List<EnergyPeak> weeklyData;

  const EnergyStats({
    this.hourlyAverage = const {},
    this.bestHour,
    this.worstHour,
    this.weeklyData = const [],
  });
}