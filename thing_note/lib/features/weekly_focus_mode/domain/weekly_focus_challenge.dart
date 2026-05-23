class WeeklyFocusChallenge {
  final int? id;
  final String weekStart;
  final String challengeTitle;
  final String? theme;
  final String? focusArea;
  final double targetHours;
  final double achievedHours;
  final int targetSessions;
  final int achievedSessions;
  final String status;
  final String? completionNote;
  final DateTime createdAt;

  WeeklyFocusChallenge({
    this.id,
    required this.weekStart,
    required this.challengeTitle,
    this.theme,
    this.focusArea,
    this.targetHours = 0,
    this.achievedHours = 0,
    this.targetSessions = 0,
    this.achievedSessions = 0,
    this.status = 'active',
    this.completionNote,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const themes = [
    {'value': 'deep_work', 'name': '深度工作', 'icon': '🎯'},
    {'value': 'creative', 'name': '创意冲刺', 'icon': '🎨'},
    {'value': 'learning', 'name': '学习周', 'icon': '📚'},
    {'value': 'health', 'name': '健康周', 'icon': '💪'},
    {'value': 'minimal', 'name': '极简周', 'icon': '🌿'},
    {'value': 'social', 'name': '社交周', 'icon': '🤝'},
  ];

  static const focusAreas = [
    '编程开发',
    '写作创作',
    '学习备考',
    '阅读思考',
    '运动健身',
    '冥想放松',
    '项目管理',
    '创意设计',
  ];

  double get hoursProgress => targetHours > 0 ? (achievedHours / targetHours).clamp(0, 1) : 0;
  double get sessionsProgress => targetSessions > 0 ? (achievedSessions / targetSessions).clamp(0, 1) : 0;
  double get overallProgress => (hoursProgress + sessionsProgress) / 2;
  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_start': weekStart,
      'challenge_title': challengeTitle,
      'theme': theme,
      'focus_area': focusArea,
      'target_hours': targetHours,
      'achieved_hours': achievedHours,
      'target_sessions': targetSessions,
      'achieved_sessions': achievedSessions,
      'status': status,
      'completion_note': completionNote,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyFocusChallenge.fromMap(Map<String, dynamic> map) {
    return WeeklyFocusChallenge(
      id: map['id'] as int?,
      weekStart: map['week_start'] as String,
      challengeTitle: map['challenge_title'] as String,
      theme: map['theme'] as String?,
      focusArea: map['focus_area'] as String?,
      targetHours: (map['target_hours'] as num?)?.toDouble() ?? 0,
      achievedHours: (map['achieved_hours'] as num?)?.toDouble() ?? 0,
      targetSessions: map['target_sessions'] as int? ?? 0,
      achievedSessions: map['achieved_sessions'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
      completionNote: map['completion_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  WeeklyFocusChallenge copyWith({
    int? id,
    String? weekStart,
    String? challengeTitle,
    String? theme,
    String? focusArea,
    double? targetHours,
    double? achievedHours,
    int? targetSessions,
    int? achievedSessions,
    String? status,
    String? completionNote,
    DateTime? createdAt,
  }) {
    return WeeklyFocusChallenge(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      theme: theme ?? this.theme,
      focusArea: focusArea ?? this.focusArea,
      targetHours: targetHours ?? this.targetHours,
      achievedHours: achievedHours ?? this.achievedHours,
      targetSessions: targetSessions ?? this.targetSessions,
      achievedSessions: achievedSessions ?? this.achievedSessions,
      status: status ?? this.status,
      completionNote: completionNote ?? this.completionNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
