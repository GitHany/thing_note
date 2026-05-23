/// Deep Work Session model
class DeepWorkSessionModel {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final int focusScore;
  final int distractionCount;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  DeepWorkSessionModel({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.focusScore = 0,
    this.distractionCount = 0,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => endedAt == null;

  Duration get duration => endedAt != null
      ? endedAt!.difference(startedAt)
      : DateTime.now().difference(startedAt);

  String get durationFormatted {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'focus_score': focusScore,
      'distraction_count': distractionCount,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DeepWorkSessionModel.fromMap(Map<String, dynamic> map) {
    return DeepWorkSessionModel(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      focusScore: map['focus_score'] as int? ?? 0,
      distractionCount: map['distraction_count'] as int? ?? 0,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DeepWorkSessionModel copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    int? focusScore,
    int? distractionCount,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return DeepWorkSessionModel(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      focusScore: focusScore ?? this.focusScore,
      distractionCount: distractionCount ?? this.distractionCount,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Deep Work Statistics model
class DeepWorkStatsModel {
  final int todayMinutes;
  final int todaySessions;
  final int todayAvgFocus;
  final int weekMinutes;
  final int weekSessions;
  final int weekAvgFocus;
  final int totalSessions;
  final int totalMinutes;
  final int avgFocusScore;

  DeepWorkStatsModel({
    required this.todayMinutes,
    required this.todaySessions,
    required this.todayAvgFocus,
    required this.weekMinutes,
    required this.weekSessions,
    required this.weekAvgFocus,
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.avgFocusScore = 0,
  });

  double get todayEfficiency => todayAvgFocus > 0 
      ? (todayAvgFocus / 5.0) * 100 
      : 0;

  double get weekEfficiency => weekAvgFocus > 0 
      ? (weekAvgFocus / 5.0) * 100 
      : 0;
}

/// Deep Work Session Filter
class DeepWorkSessionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minFocusScore;
  final int? maxDistraction;

  DeepWorkSessionFilter({
    this.startDate,
    this.endDate,
    this.minFocusScore,
    this.maxDistraction,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }
    if (minFocusScore != null) {
      params['min_focus_score'] = minFocusScore;
    }
    if (maxDistraction != null) {
      params['max_distraction'] = maxDistraction;
    }
    return params;
  }
}