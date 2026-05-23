class CreativeProject {
  final int? id;
  final String projectName;
  final String projectType;
  final String? description;
  final String status;
  final int progressPercent;
  final DateTime? startedAt;
  final DateTime? targetCompletion;
  final DateTime? completedAt;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreativeProject({
    this.id,
    required this.projectName,
    required this.projectType,
    this.description,
    this.status = 'active',
    this.progressPercent = 0,
    this.startedAt,
    this.targetCompletion,
    this.completedAt,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_name': projectName,
      'project_type': projectType,
      'description': description,
      'status': status,
      'progress_percent': progressPercent,
      'started_at': startedAt?.toIso8601String(),
      'target_completion': targetCompletion?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CreativeProject.fromMap(Map<String, dynamic> map) {
    return CreativeProject(
      id: map['id'] as int?,
      projectName: map['project_name'] as String,
      projectType: map['project_type'] as String,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'active',
      progressPercent: map['progress_percent'] as int? ?? 0,
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      targetCompletion: map['target_completion'] != null ? DateTime.parse(map['target_completion'] as String) : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  CreativeProject copyWith({
    int? id,
    String? projectName,
    String? projectType,
    String? description,
    String? status,
    int? progressPercent,
    DateTime? startedAt,
    DateTime? targetCompletion,
    DateTime? completedAt,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreativeProject(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      projectType: projectType ?? this.projectType,
      description: description ?? this.description,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      startedAt: startedAt ?? this.startedAt,
      targetCompletion: targetCompletion ?? this.targetCompletion,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CreativeSession {
  final int? id;
  final int projectId;
  final String sessionType;
  final int durationMinutes;
  final String? outputSummary;
  final int creativityRating;
  final DateTime sessionDate;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  CreativeSession({
    this.id,
    required this.projectId,
    required this.sessionType,
    this.durationMinutes = 0,
    this.outputSummary,
    this.creativityRating = 0,
    required this.sessionDate,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'session_type': sessionType,
      'duration_minutes': durationMinutes,
      'output_summary': outputSummary,
      'creativity_rating': creativityRating,
      'session_date': sessionDate.toIso8601String(),
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CreativeSession.fromMap(Map<String, dynamic> map) {
    return CreativeSession(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      sessionType: map['session_type'] as String,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      outputSummary: map['output_summary'] as String?,
      creativityRating: map['creativity_rating'] as int? ?? 0,
      sessionDate: DateTime.parse(map['session_date'] as String),
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}