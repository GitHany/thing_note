// Smart Notifications feature
// Version: 1.0
// Description: 智能通知系统，根据用户行为和偏好自动调度和优化通知

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Smart Notification Provider
final smartNotificationConfigProvider = FutureProvider<SmartNotificationConfig>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'smart_notification_config',
    limit: 1,
  );
  
  if (maps.isNotEmpty) {
    return SmartNotificationConfig.fromMap(maps.first);
  }
  
  return SmartNotificationConfig.defaultConfig();
});

final notificationScheduleProvider = FutureProvider<List<SmartNotification>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'smart_notifications',
    orderBy: 'scheduled_time ASC',
  );
  
  return maps.map((map) => SmartNotification.fromMap(map)).toList();
});

final notificationAnalyticsProvider = FutureProvider<NotificationAnalytics>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final sent = await db.query(
    'smart_notifications',
    where: 'status = ?',
    whereArgs: ['sent'],
  );
  
  final opened = await db.query(
    'smart_notifications',
    where: 'status = ? AND opened_at IS NOT NULL',
    whereArgs: ['sent'],
  );
  
  final dismissed = await db.query(
    'smart_notifications',
    where: 'status = ?',
    whereArgs: ['dismissed'],
  );
  
  return NotificationAnalytics(
    totalSent: sent.length,
    totalOpened: opened.length,
    totalDismissed: dismissed.length,
    openRate: sent.isNotEmpty ? opened.length / sent.length : 0.0,
  );
});

class SmartNotificationConfig {
  final int? id;
  final bool enabled;
  final int quietHoursStart;
  final int quietHoursEnd;
  final bool smartTiming;
  final bool batchNotifications;
  final int maxDailyNotifications;
  final List<String> disabledCategories;

  SmartNotificationConfig({
    this.id,
    this.enabled = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.smartTiming = true,
    this.batchNotifications = true,
    this.maxDailyNotifications = 10,
    this.disabledCategories = const [],
  });

  factory SmartNotificationConfig.fromMap(Map<String, dynamic> map) {
    return SmartNotificationConfig(
      id: map['id'] as int?,
      enabled: (map['enabled'] as int?) == 1,
      quietHoursStart: map['quiet_hours_start'] as int? ?? 22,
      quietHoursEnd: map['quiet_hours_end'] as int? ?? 8,
      smartTiming: (map['smart_timing'] as int?) == 1,
      batchNotifications: (map['batch_notifications'] as int?) == 1,
      maxDailyNotifications: map['max_daily'] as int? ?? 10,
      disabledCategories: (map['disabled_categories'] as String?)?.split(',') ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled ? 1 : 0,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'smart_timing': smartTiming ? 1 : 0,
      'batch_notifications': batchNotifications ? 1 : 0,
      'max_daily': maxDailyNotifications,
      'disabled_categories': disabledCategories.join(','),
    };
  }

  factory SmartNotificationConfig.defaultConfig() {
    return SmartNotificationConfig();
  }
}

class SmartNotification {
  final int? id;
  final String title;
  final String body;
  final String category;
  final DateTime scheduledTime;
  final DateTime? sentTime;
  final DateTime? openedTime;
  final String status;
  final int priority;
  final String? actionRoute;
  final String? actionData;
  final DateTime createdAt;

  SmartNotification({
    this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.scheduledTime,
    this.sentTime,
    this.openedTime,
    this.status = 'pending',
    this.priority = 1,
    this.actionRoute,
    this.actionData,
    required this.createdAt,
  });

  factory SmartNotification.fromMap(Map<String, dynamic> map) {
    return SmartNotification(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      sentTime: map['sent_time'] != null ? DateTime.parse(map['sent_time'] as String) : null,
      openedTime: map['opened_at'] != null ? DateTime.parse(map['opened_at'] as String) : null,
      status: map['status'] as String? ?? 'pending',
      priority: map['priority'] as int? ?? 1,
      actionRoute: map['action_route'] as String?,
      actionData: map['action_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'scheduled_time': scheduledTime.toIso8601String(),
      'sent_time': sentTime?.toIso8601String(),
      'opened_at': openedTime?.toIso8601String(),
      'status': status,
      'priority': priority,
      'action_route': actionRoute,
      'action_data': actionData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IconData get icon {
    switch (category) {
      case 'habit':
        return Icons.check_circle;
      case 'goal':
        return Icons.flag;
      case 'reminder':
        return Icons.alarm;
      case 'insight':
        return Icons.lightbulb;
      case 'report':
        return Icons.analytics;
      default:
        return Icons.notifications;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'habit':
        return Colors.green;
      case 'goal':
        return Colors.blue;
      case 'reminder':
        return Colors.orange;
      case 'insight':
        return Colors.purple;
      case 'report':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class NotificationAnalytics {
  final int totalSent;
  final int totalOpened;
  final int totalDismissed;
  final double openRate;

  NotificationAnalytics({
    required this.totalSent,
    required this.totalOpened,
    required this.totalDismissed,
    required this.openRate,
  });

  double get openPercent => openRate * 100;
  double get dismissPercent => totalSent > 0 ? totalDismissed / totalSent * 100 : 0;
}

// Notification Templates
class NotificationTemplates {
  static final habitReminder = SmartNotificationTemplate(
    title: '习惯提醒',
    body: '该打卡了！{habit_name}',
    category: 'habit',
    suggestion: '建议在习惯设定时间的15分钟前发送',
  );

  static final goalDeadline = SmartNotificationTemplate(
    title: '目标截止提醒',
    body: '{goal_name} 即将到期',
    category: 'goal',
    suggestion: '在截止日期前3天开始提醒',
  );

  static final dailySummary = SmartNotificationTemplate(
    title: '今日总结',
    body: '今天记录了 {count} 条内容',
    category: 'report',
    suggestion: '建议在晚上8点发送',
  );

  static final weeklyInsight = SmartNotificationTemplate(
    title: '周度洞察',
    body: '你上周表现不错！点击查看详情',
    category: 'insight',
    suggestion: '建议在每周一早上发送',
  );

  static final streakAlert = SmartNotificationTemplate(
    title: '连续打卡提醒',
    body: '你的 {habit_name} 已经连续 {days} 天了！',
    category: 'habit',
    suggestion: '在预计打卡时间发送激励',
  );
}

class SmartNotificationTemplate {
  final String title;
  final String body;
  final String category;
  final String suggestion;

  SmartNotificationTemplate({
    required this.title,
    required this.body,
    required this.category,
    required this.suggestion,
  });
}