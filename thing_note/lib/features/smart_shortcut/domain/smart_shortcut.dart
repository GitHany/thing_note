/// Smart shortcut model
class SmartShortcut {
  final int? id;
  final String name;
  final String icon;
  final String actionType; // navigate, quick_action, template
  final String? actionConfig;
  final String triggerType; // gesture, button, voice
  final String? triggerConfig;
  final bool isEnabled;
  final int useCount;
  final DateTime createdAt;

  SmartShortcut({
    this.id,
    required this.name,
    this.icon = '⚡',
    required this.actionType,
    this.actionConfig,
    required this.triggerType,
    this.triggerConfig,
    this.isEnabled = true,
    this.useCount = 0,
    required this.createdAt,
  });

  SmartShortcut copyWith({
    int? id,
    String? name,
    String? icon,
    String? actionType,
    String? actionConfig,
    String? triggerType,
    String? triggerConfig,
    bool? isEnabled,
    int? useCount,
    DateTime? createdAt,
  }) {
    return SmartShortcut(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      actionType: actionType ?? this.actionType,
      actionConfig: actionConfig ?? this.actionConfig,
      triggerType: triggerType ?? this.triggerType,
      triggerConfig: triggerConfig ?? this.triggerConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'action_type': actionType,
      'action_config': actionConfig,
      'trigger_type': triggerType,
      'trigger_config': triggerConfig,
      'is_enabled': isEnabled ? 1 : 0,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartShortcut.fromMap(Map<String, dynamic> map) {
    return SmartShortcut(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '⚡',
      actionType: map['action_type'] as String,
      actionConfig: map['action_config'] as String?,
      triggerType: map['trigger_type'] as String,
      triggerConfig: map['trigger_config'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}