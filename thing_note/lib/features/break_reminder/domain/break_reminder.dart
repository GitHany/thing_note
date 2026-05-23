class BreakReminder {
  final int? id;
  final int? focusSessionId;
  final String breakType;
  final int durationMinutes;
  final String? suggestedActivity;
  final bool completed;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  BreakReminder({
    this.id,
    this.focusSessionId,
    this.breakType = 'short',
    this.durationMinutes = 5,
    this.suggestedActivity,
    this.completed = false,
    required this.startedAt,
    this.endedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const breakTypes = {
    'short': {'name': '短暂休息', 'duration': 5, 'icon': '☕'},
    'long': {'name': '长休息', 'duration': 15, 'icon': '🍵'},
    'micro': {'name': '微休息', 'duration': 1, 'icon': '💨'},
    'movement': {'name': '活动休息', 'duration': 10, 'icon': '🏃'},
  };

  static const suggestedActivities = [
    '站起来伸展',
    '喝水',
    '看看窗外',
    '深呼吸',
    '简单走动',
    '眼保健操',
    '听一首歌',
    '整理桌面',
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'focus_session_id': focusSessionId,
      'break_type': breakType,
      'duration_minutes': durationMinutes,
      'suggested_activity': suggestedActivity,
      'completed': completed ? 1 : 0,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BreakReminder.fromMap(Map<String, dynamic> map) {
    return BreakReminder(
      id: map['id'] as int?,
      focusSessionId: map['focus_session_id'] as int?,
      breakType: map['break_type'] as String? ?? 'short',
      durationMinutes: map['duration_minutes'] as int? ?? 5,
      suggestedActivity: map['suggested_activity'] as String?,
      completed: (map['completed'] as int?) == 1,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  BreakReminder copyWith({
    int? id,
    int? focusSessionId,
    String? breakType,
    int? durationMinutes,
    String? suggestedActivity,
    bool? completed,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
  }) {
    return BreakReminder(
      id: id ?? this.id,
      focusSessionId: focusSessionId ?? this.focusSessionId,
      breakType: breakType ?? this.breakType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      suggestedActivity: suggestedActivity ?? this.suggestedActivity,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
