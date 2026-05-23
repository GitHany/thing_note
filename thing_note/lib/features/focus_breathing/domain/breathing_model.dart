enum BreathingPattern {
  relax478,
  box,
  energize,
}

extension BreathingPatternExtension on BreathingPattern {
  String get name {
    switch (this) {
      case BreathingPattern.relax478:
        return '4-7-8 放松呼吸';
      case BreathingPattern.box:
        return '盒式呼吸';
      case BreathingPattern.energize:
        return '能量呼吸';
    }
  }

  String get description {
    switch (this) {
      case BreathingPattern.relax478:
        return '吸气4秒 → 屏息7秒 → 呼气8秒\n帮助放松和入睡';
      case BreathingPattern.box:
        return '吸气4秒 → 屏息4秒 → 呼气4秒 → 屏息4秒\n平衡和专注';
      case BreathingPattern.energize:
        return '快速吸气 → 快速呼气\n提升能量水平';
    }
  }

  List<int> get phases {
    switch (this) {
      case BreathingPattern.relax478:
        return [4, 7, 8]; // inhale, hold, exhale
      case BreathingPattern.box:
        return [4, 4, 4, 4]; // inhale, hold, exhale, hold
      case BreathingPattern.energize:
        return [2, 0, 2]; // short inhale, no hold, short exhale
    }
  }
}

class BreathingSession {
  final int id;
  final String sessionType;
  final int durationSeconds;
  final bool completed;
  final DateTime startedAt;
  final DateTime? endedAt;

  BreathingSession({
    required this.id,
    required this.sessionType,
    this.durationSeconds = 0,
    this.completed = false,
    required this.startedAt,
    this.endedAt,
  });

  factory BreathingSession.fromMap(Map<String, dynamic> map) {
    return BreathingSession(
      id: map['id'] as int,
      sessionType: map['session_type'] as String,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      completed: (map['completed'] as int?) == 1,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_type': sessionType,
      'duration_seconds': durationSeconds,
      'completed': completed ? 1 : 0,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }
}

class BreathingStats {
  final int totalSessions;
  final int completedSessions;
  final int totalMinutes;
  final double completionRate;
  final String favoritePattern;

  BreathingStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalMinutes,
    required this.completionRate,
    required this.favoritePattern,
  });
}