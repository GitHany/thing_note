class HabitBrick {
  final int? id;
  final String habitName;
  final int? parentHabitId;
  final int targetBricksPerDay;
  final String brickUnit;
  final String? description;
  final bool isActive;
  final String createdAt;

  HabitBrick({
    this.id,
    required this.habitName,
    this.parentHabitId,
    this.targetBricksPerDay = 1,
    this.brickUnit = 'task',
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_name': habitName,
      'parent_habit_id': parentHabitId,
      'target_bricks_per_day': targetBricksPerDay,
      'brick_unit': brickUnit,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory HabitBrick.fromMap(Map<String, dynamic> map) {
    return HabitBrick(
      id: map['id'] as int?,
      habitName: map['habit_name'] as String,
      parentHabitId: map['parent_habit_id'] as int?,
      targetBricksPerDay: map['target_bricks_per_day'] as int? ?? 1,
      brickUnit: map['brick_unit'] as String? ?? 'task',
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  HabitBrick copyWith({
    int? id,
    String? habitName,
    int? parentHabitId,
    int? targetBricksPerDay,
    String? brickUnit,
    String? description,
    bool? isActive,
    String? createdAt,
  }) {
    return HabitBrick(
      id: id ?? this.id,
      habitName: habitName ?? this.habitName,
      parentHabitId: parentHabitId ?? this.parentHabitId,
      targetBricksPerDay: targetBricksPerDay ?? this.targetBricksPerDay,
      brickUnit: brickUnit ?? this.brickUnit,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BrickProgress {
  final int? id;
  final int brickId;
  final String recordDate;
  final int completedBricks;
  final int totalBricks;
  final String? note;
  final String createdAt;

  BrickProgress({
    this.id,
    required this.brickId,
    required this.recordDate,
    this.completedBricks = 0,
    this.totalBricks = 1,
    this.note,
    required this.createdAt,
  });

  double get completionRate => totalBricks > 0 ? completedBricks / totalBricks : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brick_id': brickId,
      'record_date': recordDate,
      'completed_bricks': completedBricks,
      'total_bricks': totalBricks,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory BrickProgress.fromMap(Map<String, dynamic> map) {
    return BrickProgress(
      id: map['id'] as int?,
      brickId: map['brick_id'] as int,
      recordDate: map['record_date'] as String,
      completedBricks: map['completed_bricks'] as int? ?? 0,
      totalBricks: map['total_bricks'] as int? ?? 1,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  BrickProgress copyWith({
    int? id,
    int? brickId,
    String? recordDate,
    int? completedBricks,
    int? totalBricks,
    String? note,
    String? createdAt,
  }) {
    return BrickProgress(
      id: id ?? this.id,
      brickId: brickId ?? this.brickId,
      recordDate: recordDate ?? this.recordDate,
      completedBricks: completedBricks ?? this.completedBricks,
      totalBricks: totalBricks ?? this.totalBricks,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}