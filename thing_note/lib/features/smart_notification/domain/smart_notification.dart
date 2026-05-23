/// Smart notification model
class SmartNotification {
  final int? id;
  final String title;
  final String? body;
  final String type; // reminder, suggestion, summary, alert
  final String? triggerConfig; // JSON config for trigger conditions
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastTriggered;

  SmartNotification({
    this.id,
    required this.title,
    this.body,
    required this.type,
    this.triggerConfig,
    this.isEnabled = true,
    required this.createdAt,
    this.lastTriggered,
  });

  SmartNotification copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    String? triggerConfig,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastTriggered,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      triggerConfig: triggerConfig ?? this.triggerConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'type': type,
      'trigger_config': triggerConfig,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_triggered': lastTriggered?.toIso8601String(),
    };
  }

  factory SmartNotification.fromMap(Map<String, dynamic> map) {
    return SmartNotification(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String?,
      type: map['type'] as String,
      triggerConfig: map['trigger_config'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
    );
  }
}

/// Notification trigger types
enum NotificationTriggerType {
  dailySummary,      // Daily summary at set time
  habitReminder,     // Habit reminder based on time
  goalDeadline,      // Goal deadline approaching
  weeklyReview,      // Weekly review reminder
  customTime,        // Custom time trigger
  locationBased,     // Location-based trigger
  eventBased,        // Event-based trigger
}

/// Notification scheduling configuration
class NotificationSchedule {
  final NotificationTriggerType type;
  final String? time; // HH:mm format
  final List<int>? weekdays; // 1-7 for Mon-Sun
  final String? locationId;
  final String? eventId;

  NotificationSchedule({
    required this.type,
    this.time,
    this.weekdays,
    this.locationId,
    this.eventId,
  });
}