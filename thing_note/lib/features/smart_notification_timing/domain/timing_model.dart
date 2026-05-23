class NotificationTimingRule {
  final int id;
  final String notificationType;
  final int? optimalHour;
  final int? optimalMinute;
  final String? dayOfWeek;
  final double responseRate;
  final int sampleCount;
  final DateTime? lastUpdated;

  NotificationTimingRule({
    required this.id,
    required this.notificationType,
    this.optimalHour,
    this.optimalMinute,
    this.dayOfWeek,
    this.responseRate = 0,
    this.sampleCount = 0,
    this.lastUpdated,
  });

  factory NotificationTimingRule.fromMap(Map<String, dynamic> map) {
    return NotificationTimingRule(
      id: map['id'] as int,
      notificationType: map['notification_type'] as String,
      optimalHour: map['optimal_hour'] as int?,
      optimalMinute: map['optimal_minute'] as int?,
      dayOfWeek: map['day_of_week'] as String?,
      responseRate: (map['response_rate'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sample_count'] as int? ?? 0,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_type': notificationType,
      'optimal_hour': optimalHour,
      'optimal_minute': optimalMinute,
      'day_of_week': dayOfWeek,
      'response_rate': responseRate,
      'sample_count': sampleCount,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

class TimingStats {
  final int totalRules;
  final double averageResponseRate;
  final String bestTiming;
  final List<NotificationTimingRule> rules;

  TimingStats({
    required this.totalRules,
    required this.averageResponseRate,
    required this.bestTiming,
    required this.rules,
  });
}