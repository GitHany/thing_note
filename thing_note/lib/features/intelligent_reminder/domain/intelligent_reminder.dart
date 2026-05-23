class IntelligentReminder {
  final int? id;
  final String title;
  final String triggerType; // 'time', 'location', 'behavior', 'mood'
  final String? triggerConfig;
  final String actionType; // 'notification', 'record', 'habit'
  final String? actionConfig;
  final bool isEnabled;
  final double effectivenessScore;
  final int triggeredCount;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  IntelligentReminder({
    this.id,
    required this.title,
    required this.triggerType,
    this.triggerConfig,
    required this.actionType,
    this.actionConfig,
    this.isEnabled = true,
    this.effectivenessScore = 0,
    this.triggeredCount = 0,
    this.lastTriggered,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'trigger_type': triggerType,
      'trigger_config': triggerConfig,
      'action_type': actionType,
      'action_config': actionConfig,
      'is_enabled': isEnabled ? 1 : 0,
      'effectiveness_score': effectivenessScore,
      'triggered_count': triggeredCount,
      'last_triggered': lastTriggered?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IntelligentReminder.fromMap(Map<String, dynamic> map) {
    return IntelligentReminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      triggerType: map['trigger_type'] as String,
      triggerConfig: map['trigger_config'] as String?,
      actionType: map['action_type'] as String,
      actionConfig: map['action_config'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      effectivenessScore: (map['effectiveness_score'] as num?)?.toDouble() ?? 0,
      triggeredCount: map['triggered_count'] as int? ?? 0,
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IntelligentReminder copyWith({
    int? id,
    String? title,
    String? triggerType,
    String? triggerConfig,
    String? actionType,
    String? actionConfig,
    bool? isEnabled,
    double? effectivenessScore,
    int? triggeredCount,
    DateTime? lastTriggered,
    DateTime? createdAt,
  }) {
    return IntelligentReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      triggerType: triggerType ?? this.triggerType,
      triggerConfig: triggerConfig ?? this.triggerConfig,
      actionType: actionType ?? this.actionType,
      actionConfig: actionConfig ?? this.actionConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      effectivenessScore: effectivenessScore ?? this.effectivenessScore,
      triggeredCount: triggeredCount ?? this.triggeredCount,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}