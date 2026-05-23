class CelebrationEvent {
  final int? id;
  final String eventType;
  final String title;
  final String? description;
  final String celebrationStyle;
  final String? triggeredBy;
  final int? triggerId;
  final DateTime triggeredAt;
  final bool isDisplayed;
  final DateTime createdAt;

  CelebrationEvent({
    this.id,
    required this.eventType,
    required this.title,
    this.description,
    this.celebrationStyle = 'confetti',
    this.triggeredBy,
    this.triggerId,
    required this.triggeredAt,
    this.isDisplayed = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const eventTypes = [
    {'value': 'habit_streak', 'name': '习惯连续', 'icon': '🔥', 'desc': '连续打卡达成'},
    {'value': 'goal_completed', 'name': '目标完成', 'icon': '🎯', 'desc': '目标达成'},
    {'value': 'milestone_reached', 'name': '里程碑', 'icon': '🏆', 'desc': '重要里程碑'},
    {'value': 'streak_broken', 'name': '连续中断', 'icon': '💔', 'desc': '连续记录中断'},
    {'value': 'level_up', 'name': '等级提升', 'icon': '⬆️', 'desc': '等级提升'},
    {'value': 'achievement_unlock', 'name': '成就解锁', 'icon': '🏅', 'desc': '新成就解锁'},
    {'value': 'perfect_day', 'name': '完美一天', 'icon': '⭐', 'desc': '完成所有计划'},
    {'value': 'focus_hour', 'name': '专注时长', 'icon': '⏱️', 'desc': '专注时长达成'},
  ];

  static const celebrationStyles = [
    {'value': 'confetti', 'name': '彩色纸屑', 'icon': '🎊'},
    {'value': 'fireworks', 'name': '烟花', 'icon': '🎆'},
    {'value': 'stars', 'name': '星星', 'icon': '✨'},
    {'value': 'simple', 'name': '简洁', 'icon': '👏'},
    {'value': 'none', 'name': '无动画', 'icon': '😌'},
  ];

  String get eventIcon {
    return eventTypes
        .firstWhere((e) => e['value'] == eventType,
            orElse: () => {'icon': '🎉'})['icon'] ??
        '🎉';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_type': eventType,
      'title': title,
      'description': description,
      'celebration_style': celebrationStyle,
      'triggered_by': triggeredBy,
      'trigger_id': triggerId,
      'triggered_at': triggeredAt.toIso8601String(),
      'is_displayed': isDisplayed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CelebrationEvent.fromMap(Map<String, dynamic> map) {
    return CelebrationEvent(
      id: map['id'] as int?,
      eventType: map['event_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      celebrationStyle: map['celebration_style'] as String? ?? 'confetti',
      triggeredBy: map['triggered_by'] as String?,
      triggerId: map['trigger_id'] as int?,
      triggeredAt: DateTime.parse(map['triggered_at'] as String),
      isDisplayed: (map['is_displayed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
