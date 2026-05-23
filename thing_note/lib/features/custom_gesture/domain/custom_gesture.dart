import 'dart:convert';

class CustomGesture {
  final int? id;
  final String name;
  final String gestureType; // 'swipe', 'tap', 'long_press', 'double_tap'
  final String? gestureConfig;
  final String actionType; // 'navigate', 'action', 'shortcut'
  final String? actionConfig;
  final bool isEnabled;
  final int useCount;
  final DateTime createdAt;

  CustomGesture({
    this.id,
    required this.name,
    required this.gestureType,
    this.gestureConfig,
    required this.actionType,
    this.actionConfig,
    this.isEnabled = true,
    this.useCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gesture_type': gestureType,
      'gesture_config': gestureConfig,
      'action_type': actionType,
      'action_config': actionConfig,
      'is_enabled': isEnabled ? 1 : 0,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomGesture.fromMap(Map<String, dynamic> map) {
    return CustomGesture(
      id: map['id'] as int?,
      name: map['name'] as String,
      gestureType: map['gesture_type'] as String,
      gestureConfig: map['gesture_config'] as String?,
      actionType: map['action_type'] as String,
      actionConfig: map['action_config'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic>? parseConfig() {
    if (gestureConfig == null) return null;
    return jsonDecode(gestureConfig!) as Map<String, dynamic>;
  }
}