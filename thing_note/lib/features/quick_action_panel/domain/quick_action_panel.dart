/// Quick action panel item
class QuickActionPanelItem {
  final int? id;
  final String name;
  final String icon;
  final String actionType;
  final String? actionPayload;
  final int order;
  final bool isVisible;
  final DateTime createdAt;

  QuickActionPanelItem({
    this.id,
    required this.name,
    this.icon = '⚡',
    required this.actionType,
    this.actionPayload,
    this.order = 0,
    this.isVisible = true,
    required this.createdAt,
  });

  QuickActionPanelItem copyWith({
    int? id,
    String? name,
    String? icon,
    String? actionType,
    String? actionPayload,
    int? order,
    bool? isVisible,
    DateTime? createdAt,
  }) {
    return QuickActionPanelItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      actionType: actionType ?? this.actionType,
      actionPayload: actionPayload ?? this.actionPayload,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'action_type': actionType,
      'action_payload': actionPayload,
      'action_order': order,
      'is_visible': isVisible ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickActionPanelItem.fromMap(Map<String, dynamic> map) {
    return QuickActionPanelItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '⚡',
      actionType: map['action_type'] as String,
      actionPayload: map['action_payload'] as String?,
      order: map['action_order'] as int? ?? 0,
      isVisible: (map['is_visible'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}