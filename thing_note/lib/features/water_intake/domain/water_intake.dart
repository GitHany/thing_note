/// 饮水追踪数据模型
class WaterIntake {
  final int? id;
  final int amountMl;
  final String? unit;
  final DateTime recordedAt;
  final DateTime createdAt;

  const WaterIntake({
    this.id,
    required this.amountMl,
    this.unit = 'ml',
    required this.recordedAt,
    required this.createdAt,
  });

  WaterIntake copyWith({
    int? id,
    int? amountMl,
    String? unit,
    DateTime? recordedAt,
    DateTime? createdAt,
  }) {
    return WaterIntake(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get amountInLiters => amountMl / 1000.0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount_ml': amountMl,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'] as int?,
      amountMl: map['amount_ml'] as int,
      unit: map['unit'] as String? ?? 'ml',
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 每日饮水目标
class WaterGoal {
  final int? id;
  final int targetMl;
  final bool isActive;
  final DateTime createdAt;

  const WaterGoal({
    this.id,
    required this.targetMl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'target_ml': targetMl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WaterGoal.fromMap(Map<String, dynamic> map) {
    return WaterGoal(
      id: map['id'] as int?,
      targetMl: map['target_ml'] as int,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}