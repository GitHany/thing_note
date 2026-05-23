class DailyRitual {
  final int? id;
  final String name;
  final String? description;
  final String timeOfDay; // morning, afternoon, evening, night
  final String? icon;
  final int orderIndex;
  final bool isActive;
  final DateTime createdAt;

  DailyRitual({
    this.id,
    required this.name,
    this.description,
    required this.timeOfDay,
    this.icon,
    required this.orderIndex,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'time_of_day': timeOfDay,
      'icon': icon,
      'order_index': orderIndex,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyRitual.fromMap(Map<String, dynamic> map) {
    return DailyRitual(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      timeOfDay: map['time_of_day'] as String,
      icon: map['icon'] as String?,
      orderIndex: map['order_index'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyRitual copyWith({
    int? id,
    String? name,
    String? description,
    String? timeOfDay,
    String? icon,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DailyRitual(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      icon: icon ?? this.icon,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RitualCompletion {
  final int? id;
  final int ritualId;
  final DateTime completedAt;
  final String? notes;
  final int? moodBefore;
  final int? moodAfter;

  RitualCompletion({
    this.id,
    required this.ritualId,
    required this.completedAt,
    this.notes,
    this.moodBefore,
    this.moodAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ritual_id': ritualId,
      'completed_at': completedAt.toIso8601String(),
      'notes': notes,
      'mood_before': moodBefore,
      'mood_after': moodAfter,
    };
  }

  factory RitualCompletion.fromMap(Map<String, dynamic> map) {
    return RitualCompletion(
      id: map['id'] as int?,
      ritualId: map['ritual_id'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      notes: map['notes'] as String?,
      moodBefore: map['mood_before'] as int?,
      moodAfter: map['mood_after'] as int?,
    );
  }
}