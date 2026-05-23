class ReminderAnalyticsEntry {
  final int? id;
  final int reminderId;
  final DateTime? triggeredAt;
  final bool actionTaken;
  final int snoozeCount;
  final double? effectivenessScore;
  final DateTime createdAt;

  ReminderAnalyticsEntry({
    this.id,
    required this.reminderId,
    this.triggeredAt,
    this.actionTaken = false,
    this.snoozeCount = 0,
    this.effectivenessScore,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reminder_id': reminderId,
      'triggered_at': triggeredAt?.toIso8601String(),
      'action_taken': actionTaken ? 1 : 0,
      'snooze_count': snoozeCount,
      'effectiveness_score': effectivenessScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderAnalyticsEntry.fromMap(Map<String, dynamic> map) {
    return ReminderAnalyticsEntry(
      id: map['id'] as int?,
      reminderId: map['reminder_id'] as int,
      triggeredAt: map['triggered_at'] != null 
          ? DateTime.parse(map['triggered_at'] as String) 
          : null,
      actionTaken: (map['action_taken'] as int?) == 1,
      snoozeCount: map['snooze_count'] as int? ?? 0,
      effectivenessScore: map['effectiveness_score'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get effectivenessLabel {
    if (effectivenessScore == null) return '未知';
    if (effectivenessScore! >= 0.8) return '高效';
    if (effectivenessScore! >= 0.5) return '一般';
    return '低效';
  }
}