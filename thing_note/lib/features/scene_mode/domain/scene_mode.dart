import 'package:flutter/material.dart';

class SceneMode {
  final int? id;
  final String name;
  final String? icon;
  final String? color;
  final String notificationMode;
  final int? defaultReminderOffset;
  final String? themeMode;
  final bool isActive;
  final String createdAt;

  SceneMode({
    this.id,
    required this.name,
    this.icon,
    this.color,
    this.notificationMode = 'all',
    this.defaultReminderOffset,
    this.themeMode,
    this.isActive = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'notification_mode': notificationMode,
      'default_reminder_offset': defaultReminderOffset,
      'theme_mode': themeMode,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory SceneMode.fromMap(Map<String, dynamic> map) {
    return SceneMode(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      notificationMode: map['notification_mode'] as String? ?? 'all',
      defaultReminderOffset: map['default_reminder_offset'] as int?,
      themeMode: map['theme_mode'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  SceneMode copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? notificationMode,
    int? defaultReminderOffset,
    String? themeMode,
    bool? isActive,
    String? createdAt,
  }) {
    return SceneMode(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      notificationMode: notificationMode ?? this.notificationMode,
      defaultReminderOffset: defaultReminderOffset ?? this.defaultReminderOffset,
      themeMode: themeMode ?? this.themeMode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get iconData {
    switch (icon) {
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'home': return Icons.home;
      case 'travel': return Icons.flight;
      case 'sports': return Icons.sports;
      case 'music': return Icons.music_note;
      case 'meeting': return Icons.groups;
      case 'rest': return Icons.weekend;
      case 'focus': return Icons.psychology;
      case 'sleep': return Icons.bedtime;
      default: return Icons.grid_view;
    }
  }

  Color get colorValue {
    switch (color) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'teal': return Colors.teal;
      default: return Colors.blueGrey;
    }
  }

  String get notificationLabel {
    switch (notificationMode) {
      case 'all': return '全部通知';
      case 'priority': return '仅优先通知';
      case 'silent': return '免打扰';
      case 'none': return '完全静音';
      default: return '全部通知';
    }
  }

  static List<SceneMode> get defaultScenes {
    final now = DateTime.now().toIso8601String();
    return [
      SceneMode(
        name: '工作模式',
        icon: 'work',
        color: 'blue',
        notificationMode: 'priority',
        defaultReminderOffset: 30,
        themeMode: 'light',
        createdAt: now,
      ),
      SceneMode(
        name: '学习模式',
        icon: 'school',
        color: 'green',
        notificationMode: 'silent',
        defaultReminderOffset: 60,
        themeMode: 'light',
        createdAt: now,
      ),
      SceneMode(
        name: '居家模式',
        icon: 'home',
        color: 'orange',
        notificationMode: 'all',
        defaultReminderOffset: 15,
        themeMode: 'dark',
        createdAt: now,
      ),
      SceneMode(
        name: '休息模式',
        icon: 'rest',
        color: 'purple',
        notificationMode: 'silent',
        themeMode: 'dark',
        createdAt: now,
      ),
    ];
  }
}

class SceneSwitchHistory {
  final int? id;
  final int sceneId;
  final String switchedAt;
  final String? triggerType;

  SceneSwitchHistory({
    this.id,
    required this.sceneId,
    required this.switchedAt,
    this.triggerType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scene_id': sceneId,
      'switched_at': switchedAt,
      'trigger_type': triggerType,
    };
  }

  factory SceneSwitchHistory.fromMap(Map<String, dynamic> map) {
    return SceneSwitchHistory(
      id: map['id'] as int?,
      sceneId: map['scene_id'] as int,
      switchedAt: map['switched_at'] as String,
      triggerType: map['trigger_type'] as String?,
    );
  }
}
