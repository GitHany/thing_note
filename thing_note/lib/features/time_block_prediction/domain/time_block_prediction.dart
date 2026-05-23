// Time Block Prediction Models
// 时间块预测功能 - 基于历史数据预测最佳活动时间段

class TimeBlockPrediction {
  final int? id;
  final int hourStart;
  final int hourEnd;
  final String activityType;
  final String? thingName;
  final double confidenceScore; // 0-1
  final int totalOccurrences;
  final int avgDurationMinutes;
  final String? explanation;
  final DateTime? lastUsed;
  final DateTime createdAt;

  TimeBlockPrediction({
    this.id,
    required this.hourStart,
    required this.hourEnd,
    required this.activityType,
    this.thingName,
    this.confidenceScore = 0,
    this.totalOccurrences = 0,
    this.avgDurationMinutes = 0,
    this.explanation,
    this.lastUsed,
    required this.createdAt,
  });

  String get timeRange => '$hourStart:00 - $hourEnd:00';

  String get confidenceLabel {
    if (confidenceScore >= 0.8) return '非常高';
    if (confidenceScore >= 0.6) return '高';
    if (confidenceScore >= 0.4) return '中等';
    if (confidenceScore >= 0.2) return '低';
    return '不确定';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour_start': hourStart,
      'hour_end': hourEnd,
      'activity_type': activityType,
      'thing_name': thingName,
      'confidence_score': confidenceScore,
      'total_occurrences': totalOccurrences,
      'avg_duration_minutes': avgDurationMinutes,
      'explanation': explanation,
      'last_used': lastUsed?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeBlockPrediction.fromMap(Map<String, dynamic> map) {
    return TimeBlockPrediction(
      id: map['id'] as int?,
      hourStart: map['hour_start'] as int,
      hourEnd: map['hour_end'] as int,
      activityType: map['activity_type'] as String,
      thingName: map['thing_name'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      totalOccurrences: map['total_occurrences'] as int? ?? 0,
      avgDurationMinutes: map['avg_duration_minutes'] as int? ?? 0,
      explanation: map['explanation'] as String?,
      lastUsed: map['last_used'] != null
          ? DateTime.parse(map['last_used'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TimeBlockPrediction copyWith({
    int? id,
    int? hourStart,
    int? hourEnd,
    String? activityType,
    String? thingName,
    double? confidenceScore,
    int? totalOccurrences,
    int? avgDurationMinutes,
    String? explanation,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) {
    return TimeBlockPrediction(
      id: id ?? this.id,
      hourStart: hourStart ?? this.hourStart,
      hourEnd: hourEnd ?? this.hourEnd,
      activityType: activityType ?? this.activityType,
      thingName: thingName ?? this.thingName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      totalOccurrences: totalOccurrences ?? this.totalOccurrences,
      avgDurationMinutes: avgDurationMinutes ?? this.avgDurationMinutes,
      explanation: explanation ?? this.explanation,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PredictionConfig {
  final int? id;
  final bool enabled;
  final int minSampleSize;
  final bool includeWeekends;
  final int predictionDaysAhead;
  final bool autoSchedule;

  PredictionConfig({
    this.id,
    this.enabled = true,
    this.minSampleSize = 5,
    this.includeWeekends = true,
    this.predictionDaysAhead = 7,
    this.autoSchedule = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enabled': enabled ? 1 : 0,
      'min_sample_size': minSampleSize,
      'include_weekends': includeWeekends ? 1 : 0,
      'prediction_days_ahead': predictionDaysAhead,
      'auto_schedule': autoSchedule ? 1 : 0,
    };
  }

  factory PredictionConfig.fromMap(Map<String, dynamic> map) {
    return PredictionConfig(
      id: map['id'] as int?,
      enabled: (map['enabled'] as int?) == 1,
      minSampleSize: map['min_sample_size'] as int? ?? 5,
      includeWeekends: (map['include_weekends'] as int?) == 1,
      predictionDaysAhead: map['prediction_days_ahead'] as int? ?? 7,
      autoSchedule: (map['auto_schedule'] as int?) == 1,
    );
  }
}

class WeeklySchedule {
  final int? id;
  final String date;
  final List<ScheduledBlock> blocks;
  final DateTime createdAt;

  WeeklySchedule({
    this.id,
    required this.date,
    required this.blocks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'blocks': blocks.map((b) => '${b.hour}:${b.activity}').join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ScheduledBlock {
  final int hour;
  final String activity;
  final int? thingNameId;
  final double confidence;

  ScheduledBlock({
    required this.hour,
    required this.activity,
    this.thingNameId,
    this.confidence = 0,
  });
}