/// Focus Zone model
class FocusZone {
  final int? id;
  final String name;
  final int focusDurationMinutes;
  final int breakDurationMinutes;
  final int longBreakDuration;
  final String color;
  final bool isActive;
  final DateTime createdAt;

  FocusZone({
    this.id,
    required this.name,
    this.focusDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.longBreakDuration = 15,
    this.color = '#2196F3',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'focus_duration_minutes': focusDurationMinutes,
      'break_duration_minutes': breakDurationMinutes,
      'long_break_duration': longBreakDuration,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusZone.fromMap(Map<String, dynamic> map) {
    return FocusZone(
      id: map['id'] as int?,
      name: map['name'] as String,
      focusDurationMinutes: map['focus_duration_minutes'] as int? ?? 25,
      breakDurationMinutes: map['break_duration_minutes'] as int? ?? 5,
      longBreakDuration: map['long_break_duration'] as int? ?? 15,
      color: map['color'] as String? ?? '#2196F3',
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FocusZone copyWith({
    int? id,
    String? name,
    int? focusDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDuration,
    String? color,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return FocusZone(
      id: id ?? this.id,
      name: name ?? this.name,
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}