/// Enhanced reminder model with more control options
class EnhancedReminder {
  final int? id;
  final int recordId;
  final DateTime remindAt;
  final String reminderType; // once, daily, weekly, monthly, yearly
  final String? customRepeatDays; // comma-separated days for custom repeat
  final int? snoozeMinutes;
  final int? snoozeCount;
  final String? soundUri;
  final String? vibrationPattern;
  final bool isEnabled;
  final bool isTriggered;
  final DateTime? triggeredAt;
  final DateTime createdAt;

  EnhancedReminder({
    this.id,
    required this.recordId,
    required this.remindAt,
    this.reminderType = 'once',
    this.customRepeatDays,
    this.snoozeMinutes = 5,
    this.snoozeCount = 0,
    this.soundUri,
    this.vibrationPattern,
    this.isEnabled = true,
    this.isTriggered = false,
    this.triggeredAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'remind_at': remindAt.toIso8601String(),
      'reminder_type': reminderType,
      'custom_repeat_days': customRepeatDays,
      'snooze_minutes': snoozeMinutes,
      'snooze_count': snoozeCount,
      'sound_uri': soundUri,
      'vibration_pattern': vibrationPattern,
      'is_enabled': isEnabled ? 1 : 0,
      'is_triggered': isTriggered ? 1 : 0,
      'triggered_at': triggeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EnhancedReminder.fromMap(Map<String, dynamic> map) {
    return EnhancedReminder(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      remindAt: DateTime.parse(map['remind_at'] as String),
      reminderType: map['reminder_type'] as String? ?? 'once',
      customRepeatDays: map['custom_repeat_days'] as String?,
      snoozeMinutes: map['snooze_minutes'] as int? ?? 5,
      snoozeCount: map['snooze_count'] as int? ?? 0,
      soundUri: map['sound_uri'] as String?,
      vibrationPattern: map['vibration_pattern'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      isTriggered: (map['is_triggered'] as int?) == 1,
      triggeredAt: map['triggered_at'] != null ? DateTime.parse(map['triggered_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  EnhancedReminder copyWith({
    int? id,
    int? recordId,
    DateTime? remindAt,
    String? reminderType,
    String? customRepeatDays,
    int? snoozeMinutes,
    int? snoozeCount,
    String? soundUri,
    String? vibrationPattern,
    bool? isEnabled,
    bool? isTriggered,
    DateTime? triggeredAt,
    DateTime? createdAt,
  }) {
    return EnhancedReminder(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      remindAt: remindAt ?? this.remindAt,
      reminderType: reminderType ?? this.reminderType,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      soundUri: soundUri ?? this.soundUri,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      isEnabled: isEnabled ?? this.isEnabled,
      isTriggered: isTriggered ?? this.isTriggered,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate next reminder time based on repeat type
  DateTime? getNextReminderTime() {
    switch (reminderType) {
      case 'daily':
        return remindAt.add(const Duration(days: 1));
      case 'weekly':
        return remindAt.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(remindAt.year, remindAt.month + 1, remindAt.day, remindAt.hour, remindAt.minute);
      case 'yearly':
        return DateTime(remindAt.year + 1, remindAt.month, remindAt.day, remindAt.hour, remindAt.minute);
      default:
        return null;
    }
  }

  /// Check if this is a recurring reminder
  bool get isRecurring => reminderType != 'once';
}

/// Reminder statistics
class ReminderStats {
  final int totalReminders;
  final int triggeredReminders;
  final int snoozedReminders;
  final int missedReminders;
  final double averageSnoozeMinutes;

  ReminderStats({
    this.totalReminders = 0,
    this.triggeredReminders = 0,
    this.snoozedReminders = 0,
    this.missedReminders = 0,
    this.averageSnoozeMinutes = 0,
  });
}

/// Reminder schedule item for display
class ReminderScheduleItem {
  final EnhancedReminder reminder;
  final String? recordTitle;
  final DateTime scheduledTime;
  final bool isPast;

  ReminderScheduleItem({
    required this.reminder,
    this.recordTitle,
    required this.scheduledTime,
    required this.isPast,
  });
}