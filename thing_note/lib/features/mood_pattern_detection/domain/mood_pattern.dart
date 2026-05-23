import 'package:flutter/material.dart';

/// Mood Pattern Model
class MoodPattern {
  final int? id;
  final String patternType;
  final String? patternData;
  final String? triggerFactors;
  final double confidenceScore;
  final DateTime? firstDetected;
  final DateTime? lastOccurred;
  final int occurrenceCount;
  final DateTime createdAt;

  MoodPattern({
    this.id,
    required this.patternType,
    this.patternData,
    this.triggerFactors,
    this.confidenceScore = 0,
    this.firstDetected,
    this.lastOccurred,
    this.occurrenceCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get patternColor {
    switch (patternType) {
      case 'positive':
      case '积极情绪周期':
        return const Color(0xFF4CAF50); // green
      case 'negative':
      case '低落情绪预警':
        return const Color(0xFFF44336); // red
      case 'cyclical':
      case '周期性波动':
        return const Color(0xFF2196F3); // blue
      case 'triggered':
      case '触发性情绪变化':
        return const Color(0xFFFF9800); // orange
      case '周末效应':
        return const Color(0xFF9C27B0); // purple
      case '工作日疲劳':
        return const Color(0xFF795548); // brown
      case '季节性变化':
        return const Color(0xFF00BCD4); // cyan
      case '压力累积':
        return const Color(0xFFE91E63); // pink
      case '恢复周期':
        return const Color(0xFF8BC34A); // light green
      default:
        return const Color(0xFF9E9E9E); // grey
    }
  }

  IconData get patternIcon {
    switch (patternType) {
      case 'positive':
      case '积极情绪周期':
        return Icons.trending_up;
      case 'negative':
      case '低落情绪预警':
        return Icons.trending_down;
      case 'cyclical':
      case '周期性波动':
        return Icons.loop;
      case 'triggered':
      case '触发性情绪变化':
        return Icons.flash_on;
      case '周末效应':
        return Icons.weekend;
      case '工作日疲劳':
        return Icons.work;
      case '季节性变化':
        return Icons.wb_sunny;
      case '压力累积':
        return Icons.psychology;
      case '恢复周期':
        return Icons.refresh;
      default:
        return Icons.show_chart;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pattern_type': patternType,
      'pattern_data': patternData,
      'trigger_factors': triggerFactors,
      'confidence_score': confidenceScore,
      'first_detected': firstDetected?.toIso8601String(),
      'last_occurred': lastOccurred?.toIso8601String(),
      'occurrence_count': occurrenceCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodPattern.fromMap(Map<String, dynamic> map) {
    return MoodPattern(
      id: map['id'] as int?,
      patternType: map['pattern_type'] as String,
      patternData: map['pattern_data'] as String?,
      triggerFactors: map['trigger_factors'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      firstDetected: map['first_detected'] != null
          ? DateTime.parse(map['first_detected'] as String)
          : null,
      lastOccurred: map['last_occurred'] != null
          ? DateTime.parse(map['last_occurred'] as String)
          : null,
      occurrenceCount: map['occurrence_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MoodPattern copyWith({
    int? id,
    String? patternType,
    String? patternData,
    String? triggerFactors,
    double? confidenceScore,
    DateTime? firstDetected,
    DateTime? lastOccurred,
    int? occurrenceCount,
    DateTime? createdAt,
  }) {
    return MoodPattern(
      id: id ?? this.id,
      patternType: patternType ?? this.patternType,
      patternData: patternData ?? this.patternData,
      triggerFactors: triggerFactors ?? this.triggerFactors,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      firstDetected: firstDetected ?? this.firstDetected,
      lastOccurred: lastOccurred ?? this.lastOccurred,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> patternTypes = [
    '周期性波动',
    '周末效应',
    '工作日疲劳',
    '季节性变化',
    '压力累积',
    '恢复周期',
  ];

  String get patternDescription {
    switch (patternType) {
      case '周期性波动':
        return '你的情绪呈现周期性变化规律';
      case '周末效应':
        return '周末通常情绪较好';
      case '工作日疲劳':
        return '工作日容易疲劳';
      case '季节性变化':
        return '情绪随季节变化';
      case '压力累积':
        return '压力会逐渐累积';
      case '恢复周期':
        return '有固定的恢复周期';
      default:
        return '发现新的情绪模式';
    }
  }
}