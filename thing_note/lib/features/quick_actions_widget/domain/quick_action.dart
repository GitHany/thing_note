/// Quick action definition
class QuickAction {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String actionType; // quick_record, template, navigation, custom
  final String? actionConfig;
  final int order;
  final bool isEnabled;
  final DateTime createdAt;

  QuickAction({
    this.id,
    required this.name,
    this.icon = '⚡',
    this.color = '#607D8B',
    required this.actionType,
    this.actionConfig,
    this.order = 0,
    this.isEnabled = true,
    required this.createdAt,
  });

  QuickAction copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? actionType,
    String? actionConfig,
    int? order,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return QuickAction(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      actionType: actionType ?? this.actionType,
      actionConfig: actionConfig ?? this.actionConfig,
      order: order ?? this.order,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'action_type': actionType,
      'action_config': actionConfig,
      'action_order': order,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickAction.fromMap(Map<String, dynamic> map) {
    return QuickAction(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '⚡',
      color: map['color'] as String? ?? '#607D8B',
      actionType: map['action_type'] as String,
      actionConfig: map['action_config'] as String?,
      order: map['action_order'] as int? ?? 0,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Widget configuration for home screen display
class WidgetConfig {
  final bool showQuickActions;
  final bool showTodaySummary;
  final bool showHabitStreak;
  final bool showRecentRecords;
  final int recentRecordsLimit;

  WidgetConfig({
    this.showQuickActions = true,
    this.showTodaySummary = true,
    this.showHabitStreak = false,
    this.showRecentRecords = true,
    this.recentRecordsLimit = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'show_quick_actions': showQuickActions,
      'show_today_summary': showTodaySummary,
      'show_habit_streak': showHabitStreak,
      'show_recent_records': showRecentRecords,
      'recent_records_limit': recentRecordsLimit,
    };
  }

  factory WidgetConfig.fromMap(Map<String, dynamic> map) {
    return WidgetConfig(
      showQuickActions: map['show_quick_actions'] as bool? ?? true,
      showTodaySummary: map['show_today_summary'] as bool? ?? true,
      showHabitStreak: map['show_habit_streak'] as bool? ?? false,
      showRecentRecords: map['show_recent_records'] as bool? ?? true,
      recentRecordsLimit: map['recent_records_limit'] as int? ?? 5,
    );
  }

  WidgetConfig copyWith({
    bool? showQuickActions,
    bool? showTodaySummary,
    bool? showHabitStreak,
    bool? showRecentRecords,
    int? recentRecordsLimit,
  }) {
    return WidgetConfig(
      showQuickActions: showQuickActions ?? this.showQuickActions,
      showTodaySummary: showTodaySummary ?? this.showTodaySummary,
      showHabitStreak: showHabitStreak ?? this.showHabitStreak,
      showRecentRecords: showRecentRecords ?? this.showRecentRecords,
      recentRecordsLimit: recentRecordsLimit ?? this.recentRecordsLimit,
    );
  }
}