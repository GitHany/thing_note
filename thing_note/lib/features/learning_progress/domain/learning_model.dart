/// Learning Subject model
class LearningSubject {
  final int? id;
  final String subject;
  final String? description;
  final int totalHours;
  final int targetHours;
  final double proficiencyLevel;
  final String status;
  final DateTime? lastStudied;
  final String? nextMilestone;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearningSubject({
    this.id,
    required this.subject,
    this.description,
    this.totalHours = 0,
    this.targetHours = 100,
    this.proficiencyLevel = 0,
    this.status = 'active',
    this.lastStudied,
    this.nextMilestone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get progressPercentage => targetHours > 0 
      ? (totalHours / targetHours * 100).clamp(0, 100) 
      : 0;

  String get proficiencyLabel {
    if (proficiencyLevel >= 90) return 'Expert';
    if (proficiencyLevel >= 70) return 'Advanced';
    if (proficiencyLevel >= 50) return 'Intermediate';
    if (proficiencyLevel >= 30) return 'Beginner';
    return 'Novice';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'total_hours': totalHours,
      'target_hours': targetHours,
      'proficiency_level': proficiencyLevel,
      'status': status,
      'last_studied': lastStudied?.toIso8601String(),
      'next_milestone': nextMilestone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LearningSubject.fromMap(Map<String, dynamic> map) {
    return LearningSubject(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      description: map['description'] as String?,
      totalHours: map['total_hours'] as int? ?? 0,
      targetHours: map['target_hours'] as int? ?? 100,
      proficiencyLevel: (map['proficiency_level'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'active',
      lastStudied: map['last_studied'] != null 
          ? DateTime.parse(map['last_studied'] as String) 
          : null,
      nextMilestone: map['next_milestone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  LearningSubject copyWith({
    int? id,
    String? subject,
    String? description,
    int? totalHours,
    int? targetHours,
    double? proficiencyLevel,
    String? status,
    DateTime? lastStudied,
    String? nextMilestone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningSubject(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      totalHours: totalHours ?? this.totalHours,
      targetHours: targetHours ?? this.targetHours,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      status: status ?? this.status,
      lastStudied: lastStudied ?? this.lastStudied,
      nextMilestone: nextMilestone ?? this.nextMilestone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Learning Session model
class LearningSession {
  final int? id;
  final String subject;
  final String? topic;
  final int durationMinutes;
  final double proficiencyLevel;
  final String? notes;
  final String? resource;
  final DateTime? completedAt;
  final DateTime sessionDate;
  final DateTime createdAt;

  LearningSession({
    this.id,
    required this.subject,
    this.topic,
    this.durationMinutes = 0,
    this.proficiencyLevel = 0,
    this.notes,
    this.resource,
    this.completedAt,
    DateTime? sessionDate,
    DateTime? createdAt,
  }) : sessionDate = sessionDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'duration_minutes': durationMinutes,
      'proficiency_level': proficiencyLevel,
      'notes': notes,
      'resource': resource,
      'completed_at': completedAt?.toIso8601String(),
      'session_date': sessionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      topic: map['topic'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      proficiencyLevel: (map['proficiency_level'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      resource: map['resource'] as String?,
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'] as String) 
          : null,
      sessionDate: DateTime.parse(map['session_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Learning Progress Statistics
class LearningStats {
  final int totalSubjects;
  final int activeSubjects;
  final int completedSubjects;
  final int totalHoursThisWeek;
  final int totalHoursThisMonth;
  final double averageProficiency;
  final String mostStudiedSubject;
  final int currentStreak;

  LearningStats({
    required this.totalSubjects,
    required this.activeSubjects,
    required this.completedSubjects,
    required this.totalHoursThisWeek,
    required this.totalHoursThisMonth,
    required this.averageProficiency,
    required this.mostStudiedSubject,
    required this.currentStreak,
  });

  factory LearningStats.empty() {
    return LearningStats(
      totalSubjects: 0,
      activeSubjects: 0,
      completedSubjects: 0,
      totalHoursThisWeek: 0,
      totalHoursThisMonth: 0,
      averageProficiency: 0,
      mostStudiedSubject: '',
      currentStreak: 0,
    );
  }
}