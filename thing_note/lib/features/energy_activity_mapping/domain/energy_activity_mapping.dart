// Energy-Activity Mapping Models
// 能量-活动映射功能 - 分析你的能量水平与活动的最佳匹配

class EnergyActivityMap {
  final int? id;
  final String activityType;
  final String? thingName;
  final int optimalEnergyLevel; // 1-5
  final double productivityScore; // 0-1
  final int sampleCount;
  final String? bestTimeRange;
  final List<String> tips;
  final DateTime lastUpdated;

  EnergyActivityMap({
    this.id,
    required this.activityType,
    this.thingName,
    required this.optimalEnergyLevel,
    this.productivityScore = 0,
    this.sampleCount = 0,
    this.bestTimeRange,
    required this.tips,
    required this.lastUpdated,
  });

  String get energyLabel {
    switch (optimalEnergyLevel) {
      case 1:
        return '低能量';
      case 2:
        return '较低能量';
      case 3:
        return '中等能量';
      case 4:
        return '较高能量';
      case 5:
        return '高能量';
      default:
        return '未知';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_type': activityType,
      'thing_name': thingName,
      'optimal_energy_level': optimalEnergyLevel,
      'productivity_score': productivityScore,
      'sample_count': sampleCount,
      'best_time_range': bestTimeRange,
      'tips': tips.join('|||'),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory EnergyActivityMap.fromMap(Map<String, dynamic> map) {
    final tipsStr = map['tips'] as String? ?? '';
    return EnergyActivityMap(
      id: map['id'] as int?,
      activityType: map['activity_type'] as String,
      thingName: map['thing_name'] as String?,
      optimalEnergyLevel: map['optimal_energy_level'] as int? ?? 3,
      productivityScore: (map['productivity_score'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sample_count'] as int? ?? 0,
      bestTimeRange: map['best_time_range'] as String?,
      tips: tipsStr.isEmpty ? [] : tipsStr.split('|||'),
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }
}

class EnergyLevel {
  final int? id;
  final int level; // 1-5
  final String label;
  final String description;
  final List<String> recommendedActivities;
  final List<String> avoidActivities;

  EnergyLevel({
    this.id,
    required this.level,
    required this.label,
    required this.description,
    required this.recommendedActivities,
    required this.avoidActivities,
  });

  String get levelEmoji {
    switch (level) {
      case 1:
        return '🔋';
      case 2:
        return '🪫';
      case 3:
        return '⚡';
      case 4:
        return '💪';
      case 5:
        return '🚀';
      default:
        return '🔌';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'label': label,
      'description': description,
      'recommended_activities': recommendedActivities.join('|||'),
      'avoid_activities': avoidActivities.join('|||'),
    };
  }

  factory EnergyLevel.fromMap(Map<String, dynamic> map) {
    final recStr = map['recommended_activities'] as String? ?? '';
    final avoidStr = map['avoid_activities'] as String? ?? '';
    return EnergyLevel(
      id: map['id'] as int?,
      level: map['level'] as int,
      label: map['label'] as String,
      description: map['description'] as String,
      recommendedActivities: recStr.isEmpty ? [] : recStr.split('|||'),
      avoidActivities: avoidStr.isEmpty ? [] : avoidStr.split('|||'),
    );
  }
}

class ActivitySchedule {
  final int? id;
  final String date;
  final List<ScheduledActivity> activities;
  final double predictedEnergyLevel;
  final DateTime generatedAt;

  ActivitySchedule({
    this.id,
    required this.date,
    required this.activities,
    required this.predictedEnergyLevel,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'activities': activities.map((a) => '${a.hour}:${a.activity}').join(','),
      'predicted_energy_level': predictedEnergyLevel,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class ScheduledActivity {
  final int hour;
  final String activity;
  final int? energyRequired;
  final double confidence;

  ScheduledActivity({
    required this.hour,
    required this.activity,
    this.energyRequired,
    this.confidence = 0,
  });
}