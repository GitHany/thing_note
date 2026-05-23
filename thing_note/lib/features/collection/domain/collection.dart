/// 收藏集数据模型
class Collection {
  final int? id;
  final String name;
  final String? description;
  final String icon;
  final int color;
  final List<int> recordIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    this.id,
    required this.name,
    this.description,
    this.icon = 'folder',
    this.color = 0xFF2196F3,
    this.recordIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Collection copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    int? color,
    List<int>? recordIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      recordIds: recordIds ?? this.recordIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get recordCount => recordIds.length;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'record_ids': recordIds.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String? ?? 'folder',
      color: map['color'] as int? ?? 0xFF2196F3,
      recordIds: (map['record_ids'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// 预设图标
class CollectionIcons {
  static const List<String> presets = [
    'folder',
    'star',
    'favorite',
    'work',
    'school',
    'fitness',
    'music',
    'camera',
    'travel',
    'home',
  ];
}