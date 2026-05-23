class FocusTimerSession {
  final int? id;
  final String title;
  final int durationMinutes;
  final int breakDuration;
  final String sessionType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isCompleted;
  final int interruptionCount;
  final int? linkedRecordId;
  final DateTime createdAt;

  FocusTimerSession({
    this.id,
    required this.title,
    required this.durationMinutes,
    this.breakDuration = 5,
    this.sessionType = 'work',
    required this.startedAt,
    this.endedAt,
    this.isCompleted = false,
    this.interruptionCount = 0,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get actualDurationMinutes {
    if (endedAt == null) return 0;
    return endedAt!.difference(startedAt).inMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'duration_minutes': durationMinutes,
      'break_duration': breakDuration,
      'session_type': sessionType,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'interruption_count': interruptionCount,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusTimerSession.fromMap(Map<String, dynamic> map) {
    return FocusTimerSession(
      id: map['id'] as int?,
      title: map['title'] as String,
      durationMinutes: map['duration_minutes'] as int,
      breakDuration: map['break_duration'] as int? ?? 5,
      sessionType: map['session_type'] as String? ?? 'work',
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      isCompleted: (map['is_completed'] as int?) == 1,
      interruptionCount: map['interruption_count'] as int? ?? 0,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FocusTimerSession copyWith({
    int? id,
    String? title,
    int? durationMinutes,
    int? breakDuration,
    String? sessionType,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isCompleted,
    int? interruptionCount,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return FocusTimerSession(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      breakDuration: breakDuration ?? this.breakDuration,
      sessionType: sessionType ?? this.sessionType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}