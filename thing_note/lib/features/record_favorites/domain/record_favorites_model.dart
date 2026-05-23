class RecordFavoriteGroup {
  final int? id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int sortOrder;
  final String? autoRules;
  final DateTime createdAt;

  RecordFavoriteGroup({
    this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.autoRules,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'auto_rules': autoRules,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecordFavoriteGroup.fromMap(Map<String, dynamic> map) {
    return RecordFavoriteGroup(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      color: map['color'],
      sortOrder: map['sort_order'] ?? 0,
      autoRules: map['auto_rules'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  RecordFavoriteGroup copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    String? autoRules,
    DateTime? createdAt,
  }) {
    return RecordFavoriteGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      autoRules: autoRules ?? this.autoRules,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}