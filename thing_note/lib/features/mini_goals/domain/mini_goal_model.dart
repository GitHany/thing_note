/// Mini Goal model
class MiniGoal {
  final int? id;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final int? actualMinutes;
  final int priority;
  final String status;
  final DateTime? completedAt;
  final String? category;
  final int? linkedRecordId;
  final DateTime createdAt;

  MiniGoal({
    this.id,
    required this.title,
    this.description,
    this.estimatedMinutes = 15,
    this.actualMinutes,
    this.priority = 1,
    this.status = 'pending',
    this.completedAt,
    this.category,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'priority': priority,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'category': category,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MiniGoal.fromMap(Map<String, dynamic> map) {
    return MiniGoal(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      estimatedMinutes: map['estimated_minutes'] as int? ?? 15,
      actualMinutes: map['actual_minutes'] as int?,
      priority: map['priority'] as int? ?? 1,
      status: map['status'] as String? ?? 'pending',
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      category: map['category'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MiniGoal copyWith({
    int? id,
    String? title,
    String? description,
    int? estimatedMinutes,
    int? actualMinutes,
    int? priority,
    String? status,
    DateTime? completedAt,
    String? category,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return MiniGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}