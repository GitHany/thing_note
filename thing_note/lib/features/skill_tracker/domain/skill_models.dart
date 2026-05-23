// Skill Tracker feature
// Version: 1.0
// Description: 技能追踪，记录技能学习进度和里程碑

class Skill {
  final int? id;
  final String name;
  final String? description;
  final String category; // programming, design, language, music, sports, other
  final int color;
  final int currentLevel; // 1-10
  final int targetLevel;
  final int totalHours;
  final String status; // learning, practicing, mastered
  final String? startedAt;
  final String? lastPracticedAt;
  final String? createdAt;

  Skill({
    this.id,
    required this.name,
    this.description,
    this.category = 'other',
    this.color = 0xFF2196F3,
    this.currentLevel = 1,
    this.targetLevel = 10,
    this.totalHours = 0,
    this.status = 'learning',
    this.startedAt,
    this.lastPracticedAt,
    this.createdAt,
  });

  double get progressPercent => 
    targetLevel > 0 ? (currentLevel / targetLevel * 100).clamp(0, 100) : 0;

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'other',
      color: map['color'] as int? ?? 0xFF2196F3,
      currentLevel: map['current_level'] as int? ?? 1,
      targetLevel: map['target_level'] as int? ?? 10,
      totalHours: map['total_hours'] as int? ?? 0,
      status: map['status'] as String? ?? 'learning',
      startedAt: map['started_at'] as String?,
      lastPracticedAt: map['last_practiced_at'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'color': color,
      'current_level': currentLevel,
      'target_level': targetLevel,
      'total_hours': totalHours,
      'status': status,
      'started_at': startedAt ?? DateTime.now().toIso8601String(),
      'last_practiced_at': lastPracticedAt,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  Skill copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    int? color,
    int? currentLevel,
    int? targetLevel,
    int? totalHours,
    String? status,
    String? startedAt,
    String? lastPracticedAt,
    String? createdAt,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      totalHours: totalHours ?? this.totalHours,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SkillMilestone {
  final int? id;
  final int skillId;
  final String title;
  final String? description;
  final int targetHours;
  final int currentHours;
  final bool isCompleted;
  final String? completedAt;
  final String? createdAt;

  SkillMilestone({
    this.id,
    required this.skillId,
    required this.title,
    this.description,
    this.targetHours = 10,
    this.currentHours = 0,
    this.isCompleted = false,
    this.completedAt,
    this.createdAt,
  });

  double get progressPercent =>
    targetHours > 0 ? (currentHours / targetHours * 100).clamp(0, 100) : 0;

  factory SkillMilestone.fromMap(Map<String, dynamic> map) {
    return SkillMilestone(
      id: map['id'] as int?,
      skillId: map['skill_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetHours: map['target_hours'] as int? ?? 10,
      currentHours: map['current_hours'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skill_id': skillId,
      'title': title,
      'description': description,
      'target_hours': targetHours,
      'current_hours': currentHours,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}