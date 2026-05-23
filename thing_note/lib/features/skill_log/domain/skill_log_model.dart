class SkillLog {
  final int? id;
  final String skillName;
  final String? description;
  final String currentLevel;
  final String? targetLevel;
  final int totalHours;
  final String? milestone;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  SkillLog({
    this.id,
    required this.skillName,
    this.description,
    this.currentLevel = 'beginner',
    this.targetLevel,
    this.totalHours = 0,
    this.milestone,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> levels = ['beginner', 'elementary', 'intermediate', 'advanced', 'expert'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skill_name': skillName,
      'description': description,
      'current_level': currentLevel,
      'target_level': targetLevel,
      'total_hours': totalHours,
      'milestone': milestone,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory SkillLog.fromMap(Map<String, dynamic> map) {
    return SkillLog(
      id: map['id'] as int?,
      skillName: map['skill_name'] as String,
      description: map['description'] as String?,
      currentLevel: map['current_level'] as String? ?? 'beginner',
      targetLevel: map['target_level'] as String?,
      totalHours: map['total_hours'] as int? ?? 0,
      milestone: map['milestone'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  SkillLog copyWith({
    int? id,
    String? skillName,
    String? description,
    String? currentLevel,
    String? targetLevel,
    int? totalHours,
    String? milestone,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return SkillLog(
      id: id ?? this.id,
      skillName: skillName ?? this.skillName,
      description: description ?? this.description,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      totalHours: totalHours ?? this.totalHours,
      milestone: milestone ?? this.milestone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SkillSession {
  final int? id;
  final int skillId;
  final int durationMinutes;
  final String? practiceType;
  final String? outputSummary;
  final int rating;
  final String sessionDate;
  final int? linkedRecordId;
  final String? note;
  final String createdAt;

  SkillSession({
    this.id,
    required this.skillId,
    required this.durationMinutes,
    this.practiceType,
    this.outputSummary,
    this.rating = 3,
    required this.sessionDate,
    this.linkedRecordId,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skill_id': skillId,
      'duration_minutes': durationMinutes,
      'practice_type': practiceType,
      'output_summary': outputSummary,
      'rating': rating,
      'session_date': sessionDate,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory SkillSession.fromMap(Map<String, dynamic> map) {
    return SkillSession(
      id: map['id'] as int?,
      skillId: map['skill_id'] as int,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      practiceType: map['practice_type'] as String?,
      outputSummary: map['output_summary'] as String?,
      rating: map['rating'] as int? ?? 3,
      sessionDate: map['session_date'] as String,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}