class PomodoroSession {
  final int? id;
  final String name;
  final int durationMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final int completedPomodoros;
  final int totalMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;

  PomodoroSession({
    this.id,
    required this.name,
    this.durationMinutes = 25,
    this.breakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.completedPomodoros = 0,
    this.totalMinutes = 0,
    DateTime? startedAt,
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'duration_minutes': durationMinutes,
      'break_minutes': breakMinutes,
      'long_break_minutes': longBreakMinutes,
      'sessions_before_long_break': sessionsBeforeLongBreak,
      'completed_pomodoros': completedPomodoros,
      'total_minutes': totalMinutes,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as int?,
      name: map['name'] as String,
      durationMinutes: map['duration_minutes'] as int,
      breakMinutes: map['break_minutes'] as int,
      longBreakMinutes: map['long_break_minutes'] as int,
      sessionsBeforeLongBreak: map['sessions_before_long_break'] as int,
      completedPomodoros: map['completed_pomodoros'] as int,
      totalMinutes: map['total_minutes'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
    );
  }

  PomodoroSession copyWith({
    int? id,
    String? name,
    int? durationMinutes,
    int? breakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    int? completedPomodoros,
    int? totalMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class PomodoroPreset {
  final String name;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessions;

  const PomodoroPreset({
    required this.name,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.sessions,
  });

  static const List<PomodoroPreset> defaults = [
    PomodoroPreset(name: 'Classic', workMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessions: 4),
    PomodoroPreset(name: 'Short Focus', workMinutes: 15, shortBreakMinutes: 3, longBreakMinutes: 10, sessions: 6),
    PomodoroPreset(name: 'Deep Work', workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 30, sessions: 4),
    PomodoroPreset(name: 'Quick Sprint', workMinutes: 10, shortBreakMinutes: 2, longBreakMinutes: 5, sessions: 8),
  ];
}