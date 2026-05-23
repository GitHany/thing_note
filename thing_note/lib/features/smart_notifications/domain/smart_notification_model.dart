/// Smart Notification model
class SmartNotification {
  final int? id;
  final String title;
  final String? body;
  final String category;
  final DateTime scheduledTime;
  final DateTime? sentTime;
  final DateTime? openedAt;
  final String status; // pending, sent, opened, dismissed
  final int priority;
  final String? actionRoute;
  final String? actionData;
  final DateTime createdAt;

  SmartNotification({
    this.id,
    required this.title,
    this.body,
    this.category = 'general',
    required this.scheduledTime,
    this.sentTime,
    this.openedAt,
    this.status = 'pending',
    this.priority = 1,
    this.actionRoute,
    this.actionData,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'scheduled_time': scheduledTime.toIso8601String(),
      'sent_time': sentTime?.toIso8601String(),
      'opened_at': openedAt?.toIso8601String(),
      'status': status,
      'priority': priority,
      'action_route': actionRoute,
      'action_data': actionData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartNotification.fromMap(Map<String, dynamic> map) {
    return SmartNotification(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String?,
      category: map['category'] as String? ?? 'general',
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      sentTime: map['sent_time'] != null 
          ? DateTime.parse(map['sent_time'] as String) 
          : null,
      openedAt: map['opened_at'] != null 
          ? DateTime.parse(map['opened_at'] as String) 
          : null,
      status: map['status'] as String? ?? 'pending',
      priority: map['priority'] as int? ?? 1,
      actionRoute: map['action_route'] as String?,
      actionData: map['action_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Smart Notification Configuration
class SmartNotificationConfig {
  final int? id;
  final bool enabled;
  final int quietHoursStart; // Hour (0-23)
  final int quietHoursEnd;   // Hour (0-23)
  final bool smartTiming;
  final bool batchNotifications;
  final int maxDaily;
  final List<String> disabledCategories;

  SmartNotificationConfig({
    this.id,
    this.enabled = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.smartTiming = true,
    this.batchNotifications = true,
    this.maxDaily = 10,
    this.disabledCategories = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enabled': enabled ? 1 : 0,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'smart_timing': smartTiming ? 1 : 0,
      'batch_notifications': batchNotifications ? 1 : 0,
      'max_daily': maxDaily,
      'disabled_categories': disabledCategories.join(','),
    };
  }

  factory SmartNotificationConfig.fromMap(Map<String, dynamic> map) {
    final categoriesStr = map['disabled_categories'] as String?;
    return SmartNotificationConfig(
      id: map['id'] as int?,
      enabled: (map['enabled'] as int?) == 1,
      quietHoursStart: map['quiet_hours_start'] as int? ?? 22,
      quietHoursEnd: map['quiet_hours_end'] as int? ?? 8,
      smartTiming: (map['smart_timing'] as int?) == 1,
      batchNotifications: (map['batch_notifications'] as int?) == 1,
      maxDaily: map['max_daily'] as int? ?? 10,
      disabledCategories: categoriesStr != null && categoriesStr.isNotEmpty 
          ? categoriesStr.split(',') 
          : [],
    );
  }

  bool isInQuietHours(DateTime time) {
    if (!enabled) return false;
    
    final hour = time.hour;
    if (quietHoursStart > quietHoursEnd) {
      // Quiet hours span midnight (e.g., 22:00 - 08:00)
      return hour >= quietHoursStart || hour < quietHoursEnd;
    } else {
      return hour >= quietHoursStart && hour < quietHoursEnd;
    }
  }
}