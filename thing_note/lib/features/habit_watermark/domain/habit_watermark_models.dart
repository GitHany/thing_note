/// 习惯水印 - Habit Watermark
/// 在记录列表中可视化显示习惯打卡状态
library;

/// 水印配置
class HabitWatermarkConfig {
  final bool enabled;
  final WatermarkPosition position;
  final WatermarkStyle style;
  final List<int> habitIds; // 要显示的 habit ID 列表
  final bool showStreak;
  final bool showIcon;
  final double opacity;

  HabitWatermarkConfig({
    this.enabled = true,
    this.position = WatermarkPosition.topLeft,
    this.style = WatermarkStyle.badge,
    this.habitIds = const [],
    this.showStreak = true,
    this.showIcon = true,
    this.opacity = 0.8,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled ? 1 : 0,
      'position': position.name,
      'style': style.name,
      'habit_ids': habitIds.join(','),
      'show_streak': showStreak ? 1 : 0,
      'show_icon': showIcon ? 1 : 0,
      'opacity': opacity,
    };
  }

  factory HabitWatermarkConfig.fromMap(Map<String, dynamic> map) {
    final idsStr = map['habit_ids'] as String? ?? '';
    return HabitWatermarkConfig(
      enabled: (map['enabled'] as int?) == 1,
      position: WatermarkPosition.values.firstWhere(
        (p) => p.name == (map['position'] as String? ?? 'topLeft'),
        orElse: () => WatermarkPosition.topLeft,
      ),
      style: WatermarkStyle.values.firstWhere(
        (s) => s.name == (map['style'] as String? ?? 'badge'),
        orElse: () => WatermarkStyle.badge,
      ),
      habitIds: idsStr.isEmpty ? [] : idsStr.split(',').map((e) => int.parse(e)).toList(),
      showStreak: (map['show_streak'] as int?) == 1,
      showIcon: (map['show_icon'] as int?) == 1,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.8,
    );
  }

  HabitWatermarkConfig copyWith({
    bool? enabled,
    WatermarkPosition? position,
    WatermarkStyle? style,
    List<int>? habitIds,
    bool? showStreak,
    bool? showIcon,
    double? opacity,
  }) {
    return HabitWatermarkConfig(
      enabled: enabled ?? this.enabled,
      position: position ?? this.position,
      style: style ?? this.style,
      habitIds: habitIds ?? this.habitIds,
      showStreak: showStreak ?? this.showStreak,
      showIcon: showIcon ?? this.showIcon,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// 水印位置
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// 水印样式
enum WatermarkStyle {
  badge, // 徽章样式
  dot, // 圆点样式
  line, // 线条样式
  icon, // 图标样式
}

/// 习惯打卡状态
class HabitCheckStatus {
  final int habitId;
  final String habitName;
  final bool isCheckedToday;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastCheckTime;
  final String? icon;

  HabitCheckStatus({
    required this.habitId,
    required this.habitName,
    required this.isCheckedToday,
    required this.currentStreak,
    required this.bestStreak,
    this.lastCheckTime,
    this.icon,
  });

  /// 获取状态颜色
  int get statusColor {
    if (!isCheckedToday) return 0xFF9E9E9E; // 灰色 - 未打卡
    if (currentStreak >= 30) return 0xFF4CAF50; // 绿色 - 超长连续
    if (currentStreak >= 7) return 0xFF8BC34A; // 浅绿 - 一周连续
    if (currentStreak >= 3) return 0xFFFFC107; // 黄色 - 三天连续
    return 0xFF2196F3; // 蓝色 - 已打卡
  }
}

/// 记录习惯关联
class RecordHabitLink {
  final int recordId;
  final int habitId;
  final DateTime linkedAt;

  RecordHabitLink({
    required this.recordId,
    required this.habitId,
    required this.linkedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'habit_id': habitId,
      'linked_at': linkedAt.toIso8601String(),
    };
  }

  factory RecordHabitLink.fromMap(Map<String, dynamic> map) {
    return RecordHabitLink(
      recordId: map['record_id'] as int,
      habitId: map['habit_id'] as int,
      linkedAt: DateTime.parse(map['linked_at'] as String),
    );
  }
}