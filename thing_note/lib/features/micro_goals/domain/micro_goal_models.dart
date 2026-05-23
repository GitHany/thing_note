class MicroGoal {
  final int? id;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final int? actualMinutes;
  final int priority;
  final String status;
  final DateTime? completedAt;
  final int? parentGoalId;
  final String? category;
  final int? linkedRecordId;
  final DateTime createdAt;

  MicroGoal({
    this.id,
    required this.title,
    this.description,
    this.estimatedMinutes = 5,
    this.actualMinutes,
    this.priority = 1,
    this.status = 'pending',
    this.completedAt,
    this.parentGoalId,
    this.category,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'priority': priority,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'parent_goal_id': parentGoalId,
      'category': category,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MicroGoal.fromMap(Map<String, dynamic> map) {
    return MicroGoal(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      estimatedMinutes: map['estimated_minutes'] as int? ?? 5,
      actualMinutes: map['actual_minutes'] as int?,
      priority: map['priority'] as int? ?? 1,
      status: map['status'] as String? ?? 'pending',
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      parentGoalId: map['parent_goal_id'] as int?,
      category: map['category'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}