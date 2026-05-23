/// Goal Dependency model
class GoalDependencyModel {
  final int? id;
  final int goalId;
  final int dependsOnGoalId;
  final String? note;
  final DateTime createdAt;

  GoalDependencyModel({
    this.id,
    required this.goalId,
    required this.dependsOnGoalId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'depends_on_goal_id': dependsOnGoalId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalDependencyModel.fromMap(Map<String, dynamic> map) {
    return GoalDependencyModel(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      dependsOnGoalId: map['depends_on_goal_id'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Dependency Graph Node
class DependencyNode {
  final int goalId;
  final String goalName;
  final String status;
  final double progress;
  final List<int> dependsOn;
  final List<int> dependents;
  final int level;
  final bool isBlocked;

  DependencyNode({
    required this.goalId,
    required this.goalName,
    required this.status,
    required this.progress,
    required this.dependsOn,
    required this.dependents,
    required this.level,
    this.isBlocked = false,
  });
}

/// Dependency Path
class DependencyPath {
  final List<int> path;
  final int totalGoals;
  final int completedGoals;
  final double progress;

  DependencyPath({
    required this.path,
    required this.totalGoals,
    required this.completedGoals,
    required this.progress,
  });
}