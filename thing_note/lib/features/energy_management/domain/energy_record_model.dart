class EnergyRecord {
  final int? id;
  final String recordedAt;
  final int energyLevel;
  final String? trigger;
  final String? activity;
  final String? note;
  final String createdAt;

  EnergyRecord({
    this.id,
    required this.recordedAt,
    required this.energyLevel,
    this.trigger,
    this.activity,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recorded_at': recordedAt,
      'energy_level': energyLevel,
      'trigger': trigger,
      'activity': activity,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory EnergyRecord.fromMap(Map<String, dynamic> map) {
    return EnergyRecord(
      id: map['id'] as int?,
      recordedAt: map['recorded_at'] as String,
      energyLevel: map['energy_level'] as int? ?? 5,
      trigger: map['trigger'] as String?,
      activity: map['activity'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  EnergyRecord copyWith({
    int? id,
    String? recordedAt,
    int? energyLevel,
    String? trigger,
    String? activity,
    String? note,
    String? createdAt,
  }) {
    return EnergyRecord(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      energyLevel: energyLevel ?? this.energyLevel,
      trigger: trigger ?? this.trigger,
      activity: activity ?? this.activity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}