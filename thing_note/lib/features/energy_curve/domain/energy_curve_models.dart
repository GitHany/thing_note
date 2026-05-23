// Energy Curve feature
// Version: 1.0
// Description: 每日能量曲线追踪，记录不同时间段的精力状态，帮助识别高效时段

class EnergyCurve {
  final int? id;
  final String date; // YYYY-MM-DD
  final int hour6To8; // 6-8点精力值 1-5
  final int hour8To10; // 8-10点精力值
  final int hour10To12; // 10-12点精力值
  final int hour12To14; // 12-14点精力值
  final int hour14To16; // 14-16点精力值
  final int hour16To18; // 16-18点精力值
  final int hour18To20; // 18-20点精力值
  final int hour20To22; // 20-22点精力值
  final String? note;
  final String? createdAt;

  EnergyCurve({
    this.id,
    required this.date,
    this.hour6To8 = 0,
    this.hour8To10 = 0,
    this.hour10To12 = 0,
    this.hour12To14 = 0,
    this.hour14To16 = 0,
    this.hour16To18 = 0,
    this.hour18To20 = 0,
    this.hour20To22 = 0,
    this.note,
    this.createdAt,
  });

  List<int> get allHours => [
    hour6To8, hour8To10, hour10To12, hour12To14,
    hour14To16, hour16To18, hour18To20, hour20To22
  ];

  double get averageEnergy {
    final hours = allHours.where((h) => h > 0).toList();
    if (hours.isEmpty) return 0;
    return hours.reduce((a, b) => a + b) / hours.length;
  }

  int get peakHour {
    final hours = <MapEntry<int, int>>[];
    hours.add(MapEntry(7, hour6To8));
    hours.add(MapEntry(9, hour8To10));
    hours.add(MapEntry(11, hour10To12));
    hours.add(MapEntry(13, hour12To14));
    hours.add(MapEntry(15, hour14To16));
    hours.add(MapEntry(17, hour16To18));
    hours.add(MapEntry(19, hour18To20));
    hours.add(MapEntry(21, hour20To22));
    
    int maxHour = 7;
    int maxValue = 0;
    for (final entry in hours) {
      if (entry.value > maxValue) {
        maxValue = entry.value;
        maxHour = entry.key;
      }
    }
    return maxHour;
  }

  int get lowHour {
    final hours = <MapEntry<int, int>>[];
    hours.add(MapEntry(7, hour6To8));
    hours.add(MapEntry(9, hour8To10));
    hours.add(MapEntry(11, hour10To12));
    hours.add(MapEntry(13, hour12To14));
    hours.add(MapEntry(15, hour14To16));
    hours.add(MapEntry(17, hour16To18));
    hours.add(MapEntry(19, hour18To20));
    hours.add(MapEntry(21, hour20To22));
    
    int minHour = 7;
    int minValue = 6;
    for (final entry in hours) {
      if (entry.value > 0 && entry.value < minValue) {
        minValue = entry.value;
        minHour = entry.key;
      }
    }
    return minHour;
  }

  factory EnergyCurve.fromMap(Map<String, dynamic> map) {
    return EnergyCurve(
      id: map['id'] as int?,
      date: map['date'] as String,
      hour6To8: map['hour_6_8'] as int? ?? 0,
      hour8To10: map['hour_8_10'] as int? ?? 0,
      hour10To12: map['hour_10_12'] as int? ?? 0,
      hour12To14: map['hour_12_14'] as int? ?? 0,
      hour14To16: map['hour_14_16'] as int? ?? 0,
      hour16To18: map['hour_16_18'] as int? ?? 0,
      hour18To20: map['hour_18_20'] as int? ?? 0,
      hour20To22: map['hour_20_22'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'hour_6_8': hour6To8,
      'hour_8_10': hour8To10,
      'hour_10_12': hour10To12,
      'hour_12_14': hour12To14,
      'hour_14_16': hour14To16,
      'hour_16_18': hour16To18,
      'hour_18_20': hour18To20,
      'hour_20_22': hour20To22,
      'note': note,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  EnergyCurve copyWith({
    int? id,
    String? date,
    int? hour6To8,
    int? hour8To10,
    int? hour10To12,
    int? hour12To14,
    int? hour14To16,
    int? hour16To18,
    int? hour18To20,
    int? hour20To22,
    String? note,
    String? createdAt,
  }) {
    return EnergyCurve(
      id: id ?? this.id,
      date: date ?? this.date,
      hour6To8: hour6To8 ?? this.hour6To8,
      hour8To10: hour8To10 ?? this.hour8To10,
      hour10To12: hour10To12 ?? this.hour10To12,
      hour12To14: hour12To14 ?? this.hour12To14,
      hour14To16: hour14To16 ?? this.hour14To16,
      hour16To18: hour16To18 ?? this.hour16To18,
      hour18To20: hour18To20 ?? this.hour18To20,
      hour20To22: hour20To22 ?? this.hour20To22,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EnergyInsight {
  final String type; // peak, low, pattern
  final String title;
  final String description;
  final String recommendation;
  final int confidence; // 1-100

  EnergyInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.recommendation,
    this.confidence = 70,
  });
}