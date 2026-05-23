/// Habit Check-in Widget Model
class HabitCheckinWidget {
  final int? id;
  final String itemType;
  final String itemName;
  final String? icon;
  final String? actionConfig;
  final int sortOrder;
  final int useCount;
  final bool isEnabled;
  final DateTime createdAt;

  HabitCheckinWidget({
    this.id,
    required this.itemType,
    required this.itemName,
    this.icon,
    this.actionConfig,
    this.sortOrder = 0,
    this.useCount = 0,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_type': itemType,
      'item_name': itemName,
      'icon': icon,
      'action_config': actionConfig,
      'sort_order': sortOrder,
      'use_count': useCount,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitCheckinWidget.fromMap(Map<String, dynamic> map) {
    return HabitCheckinWidget(
      id: map['id'] as int?,
      itemType: map['item_type'] as String,
      itemName: map['item_name'] as String,
      icon: map['icon'] as String?,
      actionConfig: map['action_config'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      useCount: map['use_count'] as int? ?? 0,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  HabitCheckinWidget copyWith({
    int? id,
    String? itemType,
    String? itemName,
    String? icon,
    String? actionConfig,
    int? sortOrder,
    int? useCount,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return HabitCheckinWidget(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemName: itemName ?? this.itemName,
      icon: icon ?? this.icon,
      actionConfig: actionConfig ?? this.actionConfig,
      sortOrder: sortOrder ?? this.sortOrder,
      useCount: useCount ?? this.useCount,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}