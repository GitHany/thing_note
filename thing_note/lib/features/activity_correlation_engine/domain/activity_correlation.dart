import 'package:flutter/material.dart';

class ActivityCorrelation {
  final int? id;
  final String activityName;
  final String resultMetric;
  final double correlationScore;
  final int sampleCount;
  final double confidenceLevel;
  final DateTime lastUpdated;
  final DateTime createdAt;

  ActivityCorrelation({
    this.id,
    required this.activityName,
    required this.resultMetric,
    this.correlationScore = 0,
    this.sampleCount = 0,
    this.confidenceLevel = 0,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_name': activityName,
      'result_metric': resultMetric,
      'correlation_score': correlationScore,
      'sample_count': sampleCount,
      'confidence_level': confidenceLevel,
      'last_updated': lastUpdated.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ActivityCorrelation.fromMap(Map<String, dynamic> map) {
    return ActivityCorrelation(
      id: map['id'] as int?,
      activityName: map['activity_name'] as String,
      resultMetric: map['result_metric'] as String,
      correlationScore: (map['correlation_score'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sample_count'] as int? ?? 0,
      confidenceLevel: (map['confidence_level'] as num?)?.toDouble() ?? 0,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Color get correlationColor {
    if (correlationScore > 0.7) return Colors.green;
    if (correlationScore > 0.3) return Colors.orange;
    if (correlationScore < -0.3) return Colors.red;
    return Colors.grey;
  }

  String get correlationLabel {
    if (correlationScore > 0.7) return '强正相关';
    if (correlationScore > 0.3) return '弱正相关';
    if (correlationScore < -0.7) return '强负相关';
    if (correlationScore < -0.3) return '弱负相关';
    return '无显著关联';
  }
}