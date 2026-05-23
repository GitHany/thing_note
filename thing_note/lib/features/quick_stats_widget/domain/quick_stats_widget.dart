class QuickStatsWidgetConfig {
  final int? id;
  final String widgetName;
  final String statTypes;
  final String layoutStyle;
  final int refreshInterval;
  final bool isEnabled;
  final DateTime createdAt;

  QuickStatsWidgetConfig({
    this.id,
    required this.widgetName,
    required this.statTypes,
    this.layoutStyle = 'compact',
    this.refreshInterval = 60,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const availableStatTypesList = [
    {'value': 'records_today', 'name': '今日记录', 'icon': '📝'},
    {'value': 'habits_done', 'name': '习惯完成', 'icon': '✅'},
    {'value': 'focus_minutes', 'name': '专注时长', 'icon': '🎯'},
    {'value': 'mood_avg', 'name': '情绪均值', 'icon': '😊'},
    {'value': 'steps', 'name': '步数', 'icon': '👟'},
    {'value': 'sleep_hours', 'name': '睡眠时长', 'icon': '😴'},
    {'value': 'water_ml', 'name': '饮水量', 'icon': '💧'},
    {'value': 'weight', 'name': '体重', 'icon': '⚖️'},
    {'value': 'calories', 'name': '卡路里', 'icon': '🔥'},
    {'value': 'streak', 'name': '连续天数', 'icon': '🔥'},
    {'value': 'goals_progress', 'name': '目标进度', 'icon': '🏁'},
    {'value': 'energy_level', 'name': '精力等级', 'icon': '⚡'},
  ];

  static const layoutStyles = [
    {'value': 'compact', 'name': '紧凑', 'cols': 2},
    {'value': 'standard', 'name': '标准', 'cols': 3},
    {'value': 'expanded', 'name': '展开', 'cols': 4},
  ];

  List<String> get statTypesList => statTypes.split(',').where((s) => s.isNotEmpty).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'widget_name': widgetName,
      'stat_types': statTypes,
      'layout_style': layoutStyle,
      'refresh_interval': refreshInterval,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickStatsWidgetConfig.fromMap(Map<String, dynamic> map) {
    return QuickStatsWidgetConfig(
      id: map['id'] as int?,
      widgetName: map['widget_name'] as String,
      statTypes: map['stat_types'] as String,
      layoutStyle: map['layout_style'] as String? ?? 'compact',
      refreshInterval: map['refresh_interval'] as int? ?? 60,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
