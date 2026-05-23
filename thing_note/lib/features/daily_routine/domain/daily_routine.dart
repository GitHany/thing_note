class DailyRoutine {
  final int? id;
  final String name;
  final String timeSlot;
  final int durationMinutes;
  final String? category;
  final bool isActive;
  final DateTime createdAt;

  DailyRoutine({
    this.id,
    required this.name,
    required this.timeSlot,
    this.durationMinutes = 30,
    this.category,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'time_slot': timeSlot,
      'duration_minutes': durationMinutes,
      'category': category,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyRoutine.fromMap(Map<String, dynamic> map) {
    return DailyRoutine(
      id: map['id'] as int?,
      name: map['name'] as String,
      timeSlot: map['time_slot'] as String,
      durationMinutes: map['duration_minutes'] as int? ?? 30,
      category: map['category'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyRoutine copyWith({
    int? id,
    String? name,
    String? timeSlot,
    int? durationMinutes,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DailyRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      timeSlot: timeSlot ?? this.timeSlot,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RoutineCompletion {
  final int? id;
  final int routineId;
  final String completedDate;
  final DateTime completedAt;
  final String? note;

  RoutineCompletion({
    this.id,
    required this.routineId,
    required this.completedDate,
    required this.completedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'routine_id': routineId,
      'completed_date': completedDate,
      'completed_at': completedAt.toIso8601String(),
      'note': note,
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map) {
    return RoutineCompletion(
      id: map['id'] as int?,
      routineId: map['routine_id'] as int,
      completedDate: map['completed_date'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
      note: map['note'] as String?,
    );
  }
}