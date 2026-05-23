class HabitChallenge {
  final int? id;
  final String name;
  final String? description;
  final int targetDays;
  final int currentStreak;
  final DateTime startDate;
  final DateTime? endDate;
  final String? reward;
  final bool isActive;
  final DateTime createdAt;

  HabitChallenge({
    this.id,
    required this.name,
    this.description,
    this.targetDays = 30,
    this.currentStreak = 0,
    required this.startDate,
    this.endDate,
    this.reward,
    this.isActive = true,
    required this.createdAt,
  });

  double get progress => targetDays > 0 ? currentStreak / targetDays : 0;
  bool get isCompleted => currentStreak >= targetDays;
  int get daysRemaining => (targetDays - currentStreak).clamp(0, targetDays);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_days': targetDays,
      'current_streak': currentStreak,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'reward': reward,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitChallenge.fromMap(Map<String, dynamic> map) {
    return HabitChallenge(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      targetDays: map['target_days'] as int? ?? 30,
      currentStreak: map['current_streak'] as int? ?? 0,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      reward: map['reward'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  HabitChallenge copyWith({
    int? id,
    String? name,
    String? description,
    int? targetDays,
    int? currentStreak,
    DateTime? startDate,
    DateTime? endDate,
    String? reward,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return HabitChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetDays: targetDays ?? this.targetDays,
      currentStreak: currentStreak ?? this.currentStreak,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reward: reward ?? this.reward,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}