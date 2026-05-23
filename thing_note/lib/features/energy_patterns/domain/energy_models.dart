class EnergyPattern {
  final int? id;
  final int hourOfDay;
  final int? dayOfWeek;
  final int energyLevel;
  final String? activityType;
  final double productivityImpact;
  final int sampleCount;
  final DateTime? lastRecorded;
  final DateTime createdAt;

  EnergyPattern({
    this.id,
    required this.hourOfDay,
    this.dayOfWeek,
    required this.energyLevel,
    this.activityType,
    this.productivityImpact = 0,
    this.sampleCount = 0,
    this.lastRecorded,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hour_of_day': hourOfDay,
      'day_of_week': dayOfWeek,
      'energy_level': energyLevel,
      'activity_type': activityType,
      'productivity_impact': productivityImpact,
      'sample_count': sampleCount,
      'last_recorded': lastRecorded?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EnergyPattern.fromMap(Map<String, dynamic> map) {
    return EnergyPattern(
      id: map['id'] as int?,
      hourOfDay: map['hour_of_day'] as int,
      dayOfWeek: map['day_of_week'] as int?,
      energyLevel: map['energy_level'] as int,
      activityType: map['activity_type'] as String?,
      productivityImpact: (map['productivity_impact'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sample_count'] as int? ?? 0,
      lastRecorded: map['last_recorded'] != null ? DateTime.parse(map['last_recorded'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PeakEnergyTime {
  final int hour;
  final double avgEnergy;
  final String recommendation;

  PeakEnergyTime({
    required this.hour,
    required this.avgEnergy,
    required this.recommendation,
  });
}