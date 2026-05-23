/// 专注会话数据模型
class FocusSession {
  final int? id;
  final String title;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? linkedRecordId;
  final bool isCompleted;
  final DateTime createdAt;

  const FocusSession({
    this.id,
    required this.title,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
    this.linkedRecordId,
    this.isCompleted = false,
    required this.createdAt,
  });

  FocusSession copyWith({
    int? id,
    String? title,
    int? durationMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    int? linkedRecordId,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'duration_minutes': durationMinutes,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'linked_record_id': linkedRecordId,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as int?,
      title: map['title'] as String,
      durationMinutes: map['duration_minutes'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      linkedRecordId: map['linked_record_id'] as int?,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Duration get actualDuration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  bool get isRunning => endedAt == null && !isCompleted;
}

/// 专注统计
class FocusStats {
  final int todayMinutes;
  final int todaySessions;
  final int weekMinutes;
  final int weekSessions;
  final int monthMinutes;
  final int monthSessions;

  const FocusStats({
    this.todayMinutes = 0,
    this.todaySessions = 0,
    this.weekMinutes = 0,
    this.weekSessions = 0,
    this.monthMinutes = 0,
    this.monthSessions = 0,
  });
}