import 'package:flutter/material.dart';

class MoodPrediction {
  final int? id;
  final DateTime predictedDate;
  final int predictedMoodLevel;
  final double confidenceScore;
  final List<String> factors;
  final String predictionBasedOn;
  final int? actualMoodLevel;
  final double? predictionAccuracy;
  final DateTime createdAt;

  MoodPrediction({
    this.id,
    required this.predictedDate,
    required this.predictedMoodLevel,
    this.confidenceScore = 0,
    this.factors = const [],
    this.predictionBasedOn = '',
    this.actualMoodLevel,
    this.predictionAccuracy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'predicted_date': predictedDate.toIso8601String().split('T')[0],
      'predicted_mood_level': predictedMoodLevel,
      'confidence_score': confidenceScore,
      'factors': factors.join(','),
      'prediction_based_on': predictionBasedOn,
      'actual_mood_level': actualMoodLevel,
      'prediction_accuracy': predictionAccuracy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodPrediction.fromMap(Map<String, dynamic> map) {
    return MoodPrediction(
      id: map['id'] as int?,
      predictedDate: DateTime.parse(map['predicted_date'] as String),
      predictedMoodLevel: map['predicted_mood_level'] as int,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      factors: (map['factors'] as String?)?.split(',').where((f) => f.isNotEmpty).toList() ?? [],
      predictionBasedOn: map['prediction_based_on'] as String? ?? '',
      actualMoodLevel: map['actual_mood_level'] as int?,
      predictionAccuracy: (map['prediction_accuracy'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get predictionLabel {
    if (predictedMoodLevel >= 4) return 'Happy';
    if (predictedMoodLevel >= 3) return 'Neutral';
    if (predictedMoodLevel >= 2) return 'Slightly Low';
    return 'Low';
  }

  Color get predictionColor {
    if (predictedMoodLevel >= 4) return Colors.green;
    if (predictedMoodLevel >= 3) return Colors.blue;
    if (predictedMoodLevel >= 2) return Colors.orange;
    return Colors.red;
  }
}