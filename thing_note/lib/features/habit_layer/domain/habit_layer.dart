class HabitLayer {
  final int? id;
  final String chainName;
  final String? description;
  final int baseHabitId;
  final String layeredHabitName;
  final String completionTrigger;
  final int currentStreak;
  final int bestStreak;
  final bool isActive;
  final DateTime createdAt;

  HabitLayer({
    this.id,
    required this.chainName,
    this.description,
    required this.baseHabitId,
    required this.layeredHabitName,
    this.completionTrigger = 'after',
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const completionTriggers = [
    {'value': 'after', 'name': '在...之后完成', 'desc': '完成基础习惯后触发'},
    {'value': 'before', 'name': '在...之前完成', 'desc': '在基础习惯之前完成'},
    {'value': 'with', 'name': '与...同时', 'desc': '与基础习惯同时完成'},
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chain_name': chainName,
      'description': description,
      'base_habit_id': baseHabitId,
      'layered_habit_name': layeredHabitName,
      'completion_trigger': completionTrigger,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitLayer.fromMap(Map<String, dynamic> map) {
    return HabitLayer(
      id: map['id'] as int?,
      chainName: map['chain_name'] as String,
      description: map['description'] as String?,
      baseHabitId: map['base_habit_id'] as int,
      layeredHabitName: map['layered_habit_name'] as String,
      completionTrigger: map['completion_trigger'] as String? ?? 'after',
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  HabitLayer copyWith({
    int? id,
    String? chainName,
    String? description,
    int? baseHabitId,
    String? layeredHabitName,
    String? completionTrigger,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return HabitLayer(
      id: id ?? this.id,
      chainName: chainName ?? this.chainName,
      description: description ?? this.description,
      baseHabitId: baseHabitId ?? this.baseHabitId,
      layeredHabitName: layeredHabitName ?? this.layeredHabitName,
      completionTrigger: completionTrigger ?? this.completionTrigger,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
