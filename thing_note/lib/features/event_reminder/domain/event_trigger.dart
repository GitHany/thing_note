import 'package:flutter/material.dart';

/// 事件触发器数据模型
class EventTrigger {
  final int? id;
  final String name;
  final String triggerType;
  final String triggerConfig;
  final String actionType;
  final String actionConfig;
  final bool isEnabled;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  const EventTrigger({
    this.id,
    required this.name,
    required this.triggerType,
    required this.triggerConfig,
    required this.actionType,
    required this.actionConfig,
    this.isEnabled = true,
    this.lastTriggered,
    required this.createdAt,
  });

  EventTrigger copyWith({
    int? id,
    String? name,
    String? triggerType,
    String? triggerConfig,
    String? actionType,
    String? actionConfig,
    bool? isEnabled,
    DateTime? lastTriggered,
    DateTime? createdAt,
  }) {
    return EventTrigger(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerType: triggerType ?? this.triggerType,
      triggerConfig: triggerConfig ?? this.triggerConfig,
      actionType: actionType ?? this.actionType,
      actionConfig: actionConfig ?? this.actionConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'trigger_type': triggerType,
      'trigger_config': triggerConfig,
      'action_type': actionType,
      'action_config': actionConfig,
      'is_enabled': isEnabled ? 1 : 0,
      'last_triggered': lastTriggered?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EventTrigger.fromMap(Map<String, dynamic> map) {
    return EventTrigger(
      id: map['id'] as int?,
      name: map['name'] as String,
      triggerType: map['trigger_type'] as String,
      triggerConfig: map['trigger_config'] as String,
      actionType: map['action_type'] as String,
      actionConfig: map['action_config'] as String,
      isEnabled: (map['is_enabled'] as int?) == 1,
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 触发器类型
class TriggerType {
  static const time = 'time';
  static const location = 'location';
  static const record = 'record';
  static const manual = 'manual';

  static String getTitle(String type) {
    switch (type) {
      case time: return '时间触发';
      case location: return '位置触发';
      case record: return '记录触发';
      case manual: return '手动触发';
      default: return '触发器';
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case time: return Icons.schedule;
      case location: return Icons.location_on;
      case record: return Icons.edit_note;
      case manual: return Icons.touch_app;
      default: return Icons.notifications_active;
    }
  }
}

/// 动作类型
class ActionType {
  static const reminder = 'reminder';
  static const notification = 'notification';
  static const autoRecord = 'auto_record';

  static String getTitle(String type) {
    switch (type) {
      case reminder: return '设置提醒';
      case notification: return '发送通知';
      case autoRecord: return '自动记录';
      default: return '动作';
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case reminder: return Icons.alarm;
      case notification: return Icons.notifications;
      case autoRecord: return Icons.auto_mode;
      default: return Icons.play_arrow;
    }
  }
}