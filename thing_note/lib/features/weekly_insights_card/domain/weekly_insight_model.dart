import 'package:flutter/material.dart';

class WeeklyInsight {
  final int id;
  final String weekStart;
  final String weekEnd;
  final int recordCount;
  final double habitCompletionRate;
  final double? averageEnergy;
  final double? averageMood;
  final String? highlightsJson;
  final String? suggestions;
  final DateTime createdAt;

  WeeklyInsight({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    this.recordCount = 0,
    this.habitCompletionRate = 0,
    this.averageEnergy,
    this.averageMood,
    this.highlightsJson,
    this.suggestions,
    required this.createdAt,
  });

  factory WeeklyInsight.fromMap(Map<String, dynamic> map) {
    return WeeklyInsight(
      id: map['id'] as int,
      weekStart: map['week_start'] as String,
      weekEnd: map['week_end'] as String,
      recordCount: map['record_count'] as int? ?? 0,
      habitCompletionRate: (map['habit_completion_rate'] as num?)?.toDouble() ?? 0,
      averageEnergy: map['average_energy'] as double?,
      averageMood: map['average_mood'] as double?,
      highlightsJson: map['highlights_json'] as String?,
      suggestions: map['suggestions'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_start': weekStart,
      'week_end': weekEnd,
      'record_count': recordCount,
      'habit_completion_rate': habitCompletionRate,
      'average_energy': averageEnergy,
      'average_mood': averageMood,
      'highlights_json': highlightsJson,
      'suggestions': suggestions,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class InsightCard {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? trend;
  final String? comparison;

  InsightCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.trend,
    this.comparison,
  });
}