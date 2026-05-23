class GoalMilestone {
  final int? id;
  final int goalId;
  final String milestoneType;
  final double milestoneValue;
  final DateTime? achievedAt;
  final bool isCelebrated;
  final String? celebrationNote;
  final DateTime createdAt;

  GoalMilestone({
    this.id,
    required this.goalId,
    required this.milestoneType,
    required this.milestoneValue,
    this.achievedAt,
    this.isCelebrated = false,
    this.celebrationNote,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'milestone_type': milestoneType,
      'milestone_value': milestoneValue,
      'achieved_at': achievedAt?.toIso8601String(),
      'is_celebrated': isCelebrated ? 1 : 0,
      'celebration_note': celebrationNote,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalMilestone.fromMap(Map<String, dynamic> map) {
    return GoalMilestone(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      milestoneType: map['milestone_type'] as String,
      milestoneValue: (map['milestone_value'] as num).toDouble(),
      achievedAt: map['achieved_at'] != null ? DateTime.parse(map['achieved_at'] as String) : null,
      isCelebrated: (map['is_celebrated'] as int?) == 1,
      celebrationNote: map['celebration_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isAchieved => achievedAt != null;

  String get milestoneLabel {
    switch (milestoneType) {
      case '25%':
        return '四分之一';
      case '50%':
        return '中点';
      case '75%':
        return '四分之三';
      case '100%':
        return '完成';
      default:
        return milestoneType;
    }
  }
}