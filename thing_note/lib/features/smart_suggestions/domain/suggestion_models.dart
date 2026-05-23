/// 智能建议模型
class SmartSuggestion {
  final int? id;
  final String suggestionType; // habit, goal, reminder, record
  final String title;
  final String? description;
  final String? actionData;
  final double confidenceScore;
  final bool isAccepted;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  SmartSuggestion({
    this.id,
    required this.suggestionType,
    required this.title,
    this.description,
    this.actionData,
    this.confidenceScore = 0,
    this.isAccepted = false,
    this.acceptedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'suggestion_type': suggestionType,
      'title': title,
      'description': description,
      'action_data': actionData,
      'confidence_score': confidenceScore,
      'is_accepted': isAccepted ? 1 : 0,
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartSuggestion.fromMap(Map<String, dynamic> map) {
    return SmartSuggestion(
      id: map['id'] as int?,
      suggestionType: map['suggestion_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      actionData: map['action_data'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      isAccepted: (map['is_accepted'] as int?) == 1,
      acceptedAt: map['accepted_at'] != null ? DateTime.parse(map['accepted_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 建议历史
class SuggestionHistory {
  final int? id;
  final int suggestionId;
  final bool accepted;
  final String? feedback;
  final DateTime createdAt;

  SuggestionHistory({
    this.id,
    required this.suggestionId,
    this.accepted = false,
    this.feedback,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'suggestion_id': suggestionId,
      'accepted': accepted ? 1 : 0,
      'feedback': feedback,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SuggestionHistory.fromMap(Map<String, dynamic> map) {
    return SuggestionHistory(
      id: map['id'] as int?,
      suggestionId: map['suggestion_id'] as int,
      accepted: (map['accepted'] as int?) == 1,
      feedback: map['feedback'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 情绪矩阵数据
class MoodMatrixData {
  final int? id;
  final String activityName;
  final int energyLevel; // 1-5
  final double moodImpactScore; // -2 to +2
  final int sampleCount;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  MoodMatrixData({
    this.id,
    required this.activityName,
    required this.energyLevel,
    this.moodImpactScore = 0,
    this.sampleCount = 0,
    this.lastUpdated,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activity_name': activityName,
      'energy_level': energyLevel,
      'mood_impact_score': moodImpactScore,
      'sample_count': sampleCount,
      'last_updated': lastUpdated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodMatrixData.fromMap(Map<String, dynamic> map) {
    return MoodMatrixData(
      id: map['id'] as int?,
      activityName: map['activity_name'] as String,
      energyLevel: map['energy_level'] as int,
      moodImpactScore: (map['mood_impact_score'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sample_count'] as int? ?? 0,
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MoodMatrixData copyWith({
    int? id,
    String? activityName,
    int? energyLevel,
    double? moodImpactScore,
    int? sampleCount,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return MoodMatrixData(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      energyLevel: energyLevel ?? this.energyLevel,
      moodImpactScore: moodImpactScore ?? this.moodImpactScore,
      sampleCount: sampleCount ?? this.sampleCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}