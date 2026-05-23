class SkillProgress {
  final int? id;
  final String skillName;
  final String? category;
  final String currentLevel;
  final String? targetLevel;
  final double totalHours;
  final String? certificationName;
  final String? certificationDate;
  final String? provider;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SkillProgress({
    this.id,
    required this.skillName,
    this.category,
    this.currentLevel = 'beginner',
    this.targetLevel,
    this.totalHours = 0,
    this.certificationName,
    this.certificationDate,
    this.provider,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static const levels = ['beginner', 'elementary', 'intermediate', 'advanced', 'expert'];
  static const categories = [
    'programming',
    'language',
    'design',
    'business',
    'music',
    'sports',
    'cooking',
    'creative',
    'other'
  ];

  int get levelIndex => levels.indexOf(currentLevel);
  double get progressPercent {
    if (targetLevel == null) return 0;
    final targetIdx = levels.indexOf(targetLevel!);
    if (targetIdx <= 0) return 0;
    return (levelIndex / targetIdx * 100).clamp(0, 100);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skill_name': skillName,
      'category': category,
      'current_level': currentLevel,
      'target_level': targetLevel,
      'total_hours': totalHours,
      'certification_name': certificationName,
      'certification_date': certificationDate,
      'provider': provider,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SkillProgress.fromMap(Map<String, dynamic> map) {
    return SkillProgress(
      id: map['id'] as int?,
      skillName: map['skill_name'] as String,
      category: map['category'] as String?,
      currentLevel: map['current_level'] as String? ?? 'beginner',
      targetLevel: map['target_level'] as String?,
      totalHours: (map['total_hours'] as num?)?.toDouble() ?? 0,
      certificationName: map['certification_name'] as String?,
      certificationDate: map['certification_date'] as String?,
      provider: map['provider'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SkillProgress copyWith({
    int? id,
    String? skillName,
    String? category,
    String? currentLevel,
    String? targetLevel,
    double? totalHours,
    String? certificationName,
    String? certificationDate,
    String? provider,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillProgress(
      id: id ?? this.id,
      skillName: skillName ?? this.skillName,
      category: category ?? this.category,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      totalHours: totalHours ?? this.totalHours,
      certificationName: certificationName ?? this.certificationName,
      certificationDate: certificationDate ?? this.certificationDate,
      provider: provider ?? this.provider,
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
  final String? notes;
  final int rating;
  final DateTime sessionDate;
  final int? linkedRecordId;
  final DateTime createdAt;

  SkillSession({
    this.id,
    required this.skillId,
    required this.durationMinutes,
    this.practiceType,
    this.notes,
    this.rating = 3,
    required this.sessionDate,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skill_id': skillId,
      'duration_minutes': durationMinutes,
      'practice_type': practiceType,
      'notes': notes,
      'rating': rating,
      'session_date': sessionDate.toIso8601String(),
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SkillSession.fromMap(Map<String, dynamic> map) {
    return SkillSession(
      id: map['id'] as int?,
      skillId: map['skill_id'] as int,
      durationMinutes: map['duration_minutes'] as int,
      practiceType: map['practice_type'] as String?,
      notes: map['notes'] as String?,
      rating: map['rating'] as int? ?? 3,
      sessionDate: DateTime.parse(map['session_date'] as String),
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
