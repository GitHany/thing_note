class MatrixTask {
  final int? id;
  final String taskName;
  final String quadrant;
  final String? sourceType;
  final int? sourceId;
  final int isCompleted;
  final String? dueDate;
  final double dragRiskScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatrixTask({
    this.id,
    required this.taskName,
    required this.quadrant,
    this.sourceType,
    this.sourceId,
    this.isCompleted = 0,
    this.dueDate,
    this.dragRiskScore = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_name': taskName,
      'quadrant': quadrant,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_completed': isCompleted,
      'due_date': dueDate,
      'drag_risk_score': dragRiskScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MatrixTask.fromMap(Map<String, dynamic> map) {
    return MatrixTask(
      id: map['id'] as int?,
      taskName: map['task_name'] as String,
      quadrant: map['quadrant'] as String,
      sourceType: map['source_type'] as String?,
      sourceId: map['source_id'] as int?,
      isCompleted: map['is_completed'] as int? ?? 0,
      dueDate: map['due_date'] as String?,
      dragRiskScore: (map['drag_risk_score'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MatrixTask copyWith({
    int? id,
    String? taskName,
    String? quadrant,
    int? isCompleted,
    String? dueDate,
    double? dragRiskScore,
    DateTime? updatedAt,
  }) {
    return MatrixTask(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      quadrant: quadrant ?? this.quadrant,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      dragRiskScore: dragRiskScore ?? this.dragRiskScore,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static const List<String> quadrants = [
    'urgent_important',
    'not_urgent_important',
    'urgent_not_important',
    'not_urgent_not_important',
  ];

  static const Map<String, String> quadrantLabels = {
    'urgent_important': '重要且紧急',
    'not_urgent_important': '重要不紧急',
    'urgent_not_important': '紧急不重要',
    'not_urgent_not_important': '不重要不紧急',
  };

  static const Map<String, String> quadrantShortLabels = {
    'urgent_important': '重要紧急',
    'not_urgent_important': '重要不紧急',
    'urgent_not_important': '紧急不重要',
    'not_urgent_not_important': '不紧急不重要',
  };

  static const Map<String, int> quadrantColors = {
    'urgent_important': 0xFFF44336,
    'not_urgent_important': 0xFF2196F3,
    'urgent_not_important': 0xFFFFC107,
    'not_urgent_not_important': 0xFF9E9E9E,
  };

  static const Map<String, String> quadrantDescriptions = {
    'urgent_important': '立即处理，避免危机',
    'not_urgent_important': '规划发展，投资未来',
    'urgent_not_important': '委托他人，减少浪费',
    'not_urgent_not_important': '尽量减少，清除清单',
  };
}