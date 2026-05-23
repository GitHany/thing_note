/// 番茄钟计时数据模型
class PomodoroSession {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int focusMinutes;
  final int breakMinutes;
  final int roundsCompleted;
  final int totalSessions;
  final String sessionType; // focus / break / long_break
  final bool isCompleted;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  const PomodoroSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.roundsCompleted = 1,
    this.totalSessions = 1,
    this.sessionType = 'focus',
    this.isCompleted = true,
    this.linkedRecordId,
    this.note,
    required this.createdAt,
  });

  int get totalDurationMinutes =>
      (endedAt != null)
          ? endedAt!.difference(startedAt).inMinutes
          : focusMinutes;

  PomodoroSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? focusMinutes,
    int? breakMinutes,
    int? roundsCompleted,
    int? totalSessions,
    String? sessionType,
    bool? isCompleted,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      roundsCompleted: roundsCompleted ?? this.roundsCompleted,
      totalSessions: totalSessions ?? this.totalSessions,
      sessionType: sessionType ?? this.sessionType,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'focus_minutes': focusMinutes,
      'break_minutes': breakMinutes,
      'rounds_completed': roundsCompleted,
      'total_sessions': totalSessions,
      'session_type': sessionType,
      'is_completed': isCompleted ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      focusMinutes: map['focus_minutes'] as int? ?? 25,
      breakMinutes: map['break_minutes'] as int? ?? 5,
      roundsCompleted: map['rounds_completed'] as int? ?? 1,
      totalSessions: map['total_sessions'] as int? ?? 1,
      sessionType: map['session_type'] as String? ?? 'focus',
      isCompleted: (map['is_completed'] as int? ?? 1) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PomodoroStats {
  final int? id;
  final String date;
  final int totalSessions;
  final int totalFocusMinutes;
  final int completedRounds;
  final int longestStreak;
  final int productivityScore;
  final int? moodScore;
  final String? note;
  final DateTime createdAt;

  const PomodoroStats({
    this.id,
    required this.date,
    this.totalSessions = 0,
    this.totalFocusMinutes = 0,
    this.completedRounds = 0,
    this.longestStreak = 0,
    this.productivityScore = 0,
    this.moodScore,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'total_sessions': totalSessions,
      'total_focus_minutes': totalFocusMinutes,
      'completed_rounds': completedRounds,
      'longest_streak': longestStreak,
      'productivity_score': productivityScore,
      'mood_score': moodScore,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PomodoroStats.fromMap(Map<String, dynamic> map) {
    return PomodoroStats(
      id: map['id'] as int?,
      date: map['date'] as String,
      totalSessions: map['total_sessions'] as int? ?? 0,
      totalFocusMinutes: map['total_focus_minutes'] as int? ?? 0,
      completedRounds: map['completed_rounds'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      productivityScore: map['productivity_score'] as int? ?? 0,
      moodScore: map['mood_score'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
