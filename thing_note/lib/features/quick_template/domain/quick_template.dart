class QuickTemplate {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String? defaultThingName;
  final List<String> defaultTags;
  final int defaultDurationMinutes;
  final int useCount;
  final bool isFavorite;
  final DateTime createdAt;

  QuickTemplate({
    this.id,
    required this.name,
    required this.icon,
    this.color = '#607D8B',
    this.defaultThingName,
    this.defaultTags = const [],
    this.defaultDurationMinutes = 30,
    this.useCount = 0,
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'default_thing_name': defaultThingName,
      'default_tags': defaultTags.join(','),
      'default_duration_minutes': defaultDurationMinutes,
      'use_count': useCount,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickTemplate.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['default_tags'] as String?;
    return QuickTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String? ?? '#607D8B',
      defaultThingName: map['default_thing_name'] as String?,
      defaultTags: tagsStr != null && tagsStr.isNotEmpty
          ? tagsStr.split(',')
          : [],
      defaultDurationMinutes: map['default_duration_minutes'] as int? ?? 30,
      useCount: map['use_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  QuickTemplate copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? defaultThingName,
    List<String>? defaultTags,
    int? defaultDurationMinutes,
    int? useCount,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return QuickTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      defaultThingName: defaultThingName ?? this.defaultThingName,
      defaultTags: defaultTags ?? this.defaultTags,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      useCount: useCount ?? this.useCount,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}