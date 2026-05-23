/// 体重追踪数据模型
class WeightRecord {
  final int? id;
  final double weight;
  final double? bodyFat;
  final double? muscleMass;
  final String? unit;
  final String? note;
  final DateTime recordedAt;
  final DateTime createdAt;

  const WeightRecord({
    this.id,
    required this.weight,
    this.bodyFat,
    this.muscleMass,
    this.unit = 'kg',
    this.note,
    required this.recordedAt,
    required this.createdAt,
  });

  WeightRecord copyWith({
    int? id,
    double? weight,
    double? bodyFat,
    double? muscleMass,
    String? unit,
    String? note,
    DateTime? recordedAt,
    DateTime? createdAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'weight': weight,
      'body_fat': bodyFat,
      'muscle_mass': muscleMass,
      'unit': unit,
      'note': note,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as int?,
      weight: (map['weight'] as num).toDouble(),
      bodyFat: map['body_fat'] != null ? (map['body_fat'] as num).toDouble() : null,
      muscleMass: map['muscle_mass'] != null ? (map['muscle_mass'] as num).toDouble() : null,
      unit: map['unit'] as String? ?? 'kg',
      note: map['note'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 体重目标设置
class WeightGoal {
  final int? id;
  final double targetWeight;
  final double? startWeight;
  final String unit;
  final DateTime? deadline;
  final bool isActive;
  final DateTime createdAt;

  const WeightGoal({
    this.id,
    required this.targetWeight,
    this.startWeight,
    this.unit = 'kg',
    this.deadline,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'target_weight': targetWeight,
      'start_weight': startWeight,
      'unit': unit,
      'deadline': deadline?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeightGoal.fromMap(Map<String, dynamic> map) {
    return WeightGoal(
      id: map['id'] as int?,
      targetWeight: (map['target_weight'] as num).toDouble(),
      startWeight: map['start_weight'] != null ? (map['start_weight'] as num).toDouble() : null,
      unit: map['unit'] as String? ?? 'kg',
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}