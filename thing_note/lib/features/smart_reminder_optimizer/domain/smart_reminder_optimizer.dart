// Smart Reminder Optimizer Models
// 智能提醒优化功能 - 优化提醒时间和方式以提高响应率

class ReminderOptimization {
  final int? id;
  final int reminderId;
  final String suggestedTime;
  final String? suggestedRepeat;
  final double successRateImprovement; // 预期提升百分比
  final String? reason;
  final bool isAccepted;
  final DateTime createdAt;

  ReminderOptimization({
    this.id,
    required this.reminderId,
    required this.suggestedTime,
    this.suggestedRepeat,
    this.successRateImprovement = 0,
    this.reason,
    this.isAccepted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'suggested_time': suggestedTime,
      'suggested_repeat': suggestedRepeat,
      'success_rate_improvement': successRateImprovement,
      'reason': reason,
      'is_accepted': isAccepted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderOptimization.fromMap(Map<String, dynamic> map) {
    return ReminderOptimization(
      id: map['id'] as int?,
      reminderId: map['reminder_id'] as int,
      suggestedTime: map['suggested_time'] as String,
      suggestedRepeat: map['suggested_repeat'] as String?,
      successRateImprovement: (map['success_rate_improvement'] as num?)?.toDouble() ?? 0,
      reason: map['reason'] as String?,
      isAccepted: (map['is_accepted'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class OptimizationStrategy {
  final int? id;
  final String strategyName;
  final String description;
  final Map<String, dynamic> parameters;
  final double expectedImprovement;
  final int appliedCount;
  final bool isActive;

  OptimizationStrategy({
    this.id,
    required this.strategyName,
    required this.description,
    required this.parameters,
    this.expectedImprovement = 0,
    this.appliedCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strategy_name': strategyName,
      'description': description,
      'parameters': parameters.entries.map((e) => '${e.key}:${e.value}').join(','),
      'expected_improvement': expectedImprovement,
      'applied_count': appliedCount,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory OptimizationStrategy.fromMap(Map<String, dynamic> map) {
    return OptimizationStrategy(
      id: map['id'] as int?,
      strategyName: map['strategy_name'] as String,
      description: map['description'] as String,
      parameters: {},
      expectedImprovement: (map['expected_improvement'] as num?)?.toDouble() ?? 0,
      appliedCount: map['applied_count'] as int? ?? 0,
      isActive: (map['is_active'] as int?) == 1,
    );
  }
}

class ReminderAnalytics {
  final int? id;
  final int reminderId;
  final int totalTriggers;
  final int successfulTriggers;
  final double successRate;
  final int snoozeCount;
  final double avgSnoozeDelay;
  final String? bestTime;
  final String? bestDay;
  final DateTime calculatedAt;

  ReminderAnalytics({
    this.id,
    required this.reminderId,
    this.totalTriggers = 0,
    this.successfulTriggers = 0,
    this.successRate = 0,
    this.snoozeCount = 0,
    this.avgSnoozeDelay = 0,
    this.bestTime,
    this.bestDay,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'total_triggers': totalTriggers,
      'successful_triggers': successfulTriggers,
      'success_rate': successRate,
      'snooze_count': snoozeCount,
      'avg_snooze_delay': avgSnoozeDelay,
      'best_time': bestTime,
      'best_day': bestDay,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory ReminderAnalytics.fromMap(Map<String, dynamic> map) {
    return ReminderAnalytics(
      id: map['id'] as int?,
      reminderId: map['reminder_id'] as int,
      totalTriggers: map['total_triggers'] as int? ?? 0,
      successfulTriggers: map['successful_triggers'] as int? ?? 0,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 0,
      snoozeCount: map['snooze_count'] as int? ?? 0,
      avgSnoozeDelay: (map['avg_snooze_delay'] as num?)?.toDouble() ?? 0,
      bestTime: map['best_time'] as String?,
      bestDay: map['best_day'] as String?,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
    );
  }
}