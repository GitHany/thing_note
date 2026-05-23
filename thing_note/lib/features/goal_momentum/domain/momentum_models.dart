import 'package:flutter/material.dart';

class GoalMomentum {
  final int? id;
  final int goalId;
  final double momentumScore;
  final int streakDays;
  final double weeklyProgress;
  final double monthlyProgress;
  final DateTime? predictedCompletion;
  final List<String> riskFactors;
  final double accelerationScore;
  final DateTime lastUpdated;
  final DateTime createdAt;

  GoalMomentum({
    this.id,
    required this.goalId,
    this.momentumScore = 0,
    this.streakDays = 0,
    this.weeklyProgress = 0,
    this.monthlyProgress = 0,
    this.predictedCompletion,
    this.riskFactors = const [],
    this.accelerationScore = 0,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'goal_id': goalId,
      'momentum_score': momentumScore,
      'streak_days': streakDays,
      'weekly_progress': weeklyProgress,
      'monthly_progress': monthlyProgress,
      'predicted_completion': predictedCompletion?.toIso8601String(),
      'risk_factors': riskFactors.join(','),
      'acceleration_score': accelerationScore,
      'last_updated': lastUpdated.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalMomentum.fromMap(Map<String, dynamic> map) {
    return GoalMomentum(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      momentumScore: (map['momentum_score'] as num?)?.toDouble() ?? 0,
      streakDays: map['streak_days'] as int? ?? 0,
      weeklyProgress: (map['weekly_progress'] as num?)?.toDouble() ?? 0,
      monthlyProgress: (map['monthly_progress'] as num?)?.toDouble() ?? 0,
      predictedCompletion: map['predicted_completion'] != null
          ? DateTime.parse(map['predicted_completion'] as String)
          : null,
      riskFactors: (map['risk_factors'] as String?)?.split(',').where((r) => r.isNotEmpty).toList() ?? [],
      accelerationScore: (map['acceleration_score'] as num?)?.toDouble() ?? 0,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get momentumLabel {
    if (momentumScore >= 80) return 'Strong Momentum';
    if (momentumScore >= 60) return 'Good Progress';
    if (momentumScore >= 40) return 'Steady';
    if (momentumScore >= 20) return 'Slow';
    return 'At Risk';
  }

  Color get momentumColor {
    if (momentumScore >= 80) return Colors.green;
    if (momentumScore >= 60) return Colors.lightGreen;
    if (momentumScore >= 40) return Colors.yellow;
    if (momentumScore >= 20) return Colors.orange;
    return Colors.red;
  }
}