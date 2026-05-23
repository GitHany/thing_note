class FocusSessionAnalysis {
  final int? id;
  final int sessionId;
  final String analysisType;
  final String? distractionPattern;
  final double efficiencyScore;
  final String? bestFocusPeriod;
  final String? suggestions;
  final DateTime createdAt;

  FocusSessionAnalysis({
    this.id,
    required this.sessionId,
    required this.analysisType,
    this.distractionPattern,
    this.efficiencyScore = 0,
    this.bestFocusPeriod,
    this.suggestions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'analysis_type': analysisType,
      'distraction_pattern': distractionPattern,
      'efficiency_score': efficiencyScore,
      'best_focus_period': bestFocusPeriod,
      'suggestions': suggestions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusSessionAnalysis.fromMap(Map<String, dynamic> map) {
    return FocusSessionAnalysis(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      analysisType: map['analysis_type'] as String,
      distractionPattern: map['distraction_pattern'] as String?,
      efficiencyScore: (map['efficiency_score'] as num?)?.toDouble() ?? 0,
      bestFocusPeriod: map['best_focus_period'] as String?,
      suggestions: map['suggestions'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FocusSessionAnalysis copyWith({
    int? id,
    int? sessionId,
    String? analysisType,
    String? distractionPattern,
    double? efficiencyScore,
    String? bestFocusPeriod,
    String? suggestions,
    DateTime? createdAt,
  }) {
    return FocusSessionAnalysis(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      analysisType: analysisType ?? this.analysisType,
      distractionPattern: distractionPattern ?? this.distractionPattern,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      bestFocusPeriod: bestFocusPeriod ?? this.bestFocusPeriod,
      suggestions: suggestions ?? this.suggestions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get efficiencyGrade {
    if (efficiencyScore >= 90) return '优秀';
    if (efficiencyScore >= 75) return '良好';
    if (efficiencyScore >= 60) return '一般';
    return '待提升';
  }
}