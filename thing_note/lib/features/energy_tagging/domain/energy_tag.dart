class ActivityEnergyTag {
  final int? id;
  final String activityName;
  final int energyLevel;
  final int isRecharging;
  final int usageCount;
  final DateTime createdAt;

  ActivityEnergyTag({
    this.id,
    required this.activityName,
    required this.energyLevel,
    this.isRecharging = 0,
    this.usageCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isEnergyDraining => energyLevel >= 3 && isRecharging == 0;
  bool get isEnergyRecharging => isRecharging == 1;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activity_name': activityName,
      'energy_level': energyLevel,
      'is_recharging': isRecharging,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ActivityEnergyTag.fromMap(Map<String, dynamic> map) {
    return ActivityEnergyTag(
      id: map['id'] as int?,
      activityName: map['activity_name'] as String,
      energyLevel: map['energy_level'] as int,
      isRecharging: map['is_recharging'] as int? ?? 0,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ActivityEnergyTag copyWith({
    int? id,
    String? activityName,
    int? energyLevel,
    int? isRecharging,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return ActivityEnergyTag(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      energyLevel: energyLevel ?? this.energyLevel,
      isRecharging: isRecharging ?? this.isRecharging,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String energyLevelLabel(int level) {
    switch (level) {
      case 1:
        return '极低消耗';
      case 2:
        return '轻度消耗';
      case 3:
        return '中度消耗';
      case 4:
        return '高度消耗';
      case 5:
        return '极高消耗';
      default:
        return '未知';
    }
  }

  static int energyLevelColor(int level) {
    switch (level) {
      case 1:
        return 0xFF4CAF50;
      case 2:
        return 0xFF8BC34A;
      case 3:
        return 0xFFFFC107;
      case 4:
        return 0xFFFF9800;
      case 5:
        return 0xFFF44336;
      default:
        return 0xFF9E9E9E;
    }
  }
}