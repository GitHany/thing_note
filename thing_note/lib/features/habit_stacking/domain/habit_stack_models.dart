// Habit Stacking feature
// Version: 1.0
// Description: 习惯堆叠，将多个小习惯链接在一起，形成一个完整的习惯链

class HabitStack {
  final int? id;
  final String name;
  final String? description;
  final int color;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  HabitStack({
    this.id,
    required this.name,
    this.description,
    this.color = 0xFF2196F3,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory HabitStack.fromMap(Map<String, dynamic> map) {
    return HabitStack(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as int? ?? 0xFF2196F3,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  HabitStack copyWith({
    int? id,
    String? name,
    String? description,
    int? color,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return HabitStack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StackLink {
  final int? id;
  final int stackId;
  final int habitId;
  final int orderIndex;
  final String? triggerText; // 触发语，如"完成后喝杯水"
  final String? createdAt;

  StackLink({
    this.id,
    required this.stackId,
    required this.habitId,
    this.orderIndex = 0,
    this.triggerText,
    this.createdAt,
  });

  factory StackLink.fromMap(Map<String, dynamic> map) {
    return StackLink(
      id: map['id'] as int?,
      stackId: map['stack_id'] as int,
      habitId: map['habit_id'] as int,
      orderIndex: map['order_index'] as int? ?? 0,
      triggerText: map['trigger_text'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stack_id': stackId,
      'habit_id': habitId,
      'order_index': orderIndex,
      'trigger_text': triggerText,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class HabitStackWithLinks {
  final HabitStack stack;
  final List<StackLink> links;
  final List<String> habitNames;

  HabitStackWithLinks({
    required this.stack,
    required this.links,
    required this.habitNames,
  });
}