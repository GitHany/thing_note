/// Smart Template model for intelligent record templates
class SmartTemplate {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String? defaultThingName;
  final List<String> defaultTags;
  final int defaultDurationMinutes;
  final String? defaultNote;
  final bool isFavorite;
  final int useCount;
  final String? category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SmartTemplate({
    this.id,
    required this.name,
    this.icon = '📌',
    this.color = '#607D8B',
    this.defaultThingName,
    this.defaultTags = const [],
    this.defaultDurationMinutes = 30,
    this.defaultNote,
    this.isFavorite = false,
    this.useCount = 0,
    this.category,
    required this.createdAt,
    this.updatedAt,
  });

  SmartTemplate copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? defaultThingName,
    List<String>? defaultTags,
    int? defaultDurationMinutes,
    String? defaultNote,
    bool? isFavorite,
    int? useCount,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      defaultThingName: defaultThingName ?? this.defaultThingName,
      defaultTags: defaultTags ?? this.defaultTags,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      defaultNote: defaultNote ?? this.defaultNote,
      isFavorite: isFavorite ?? this.isFavorite,
      useCount: useCount ?? this.useCount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'default_thing_name': defaultThingName,
      'default_tags': defaultTags.join(','),
      'default_duration_minutes': defaultDurationMinutes,
      'default_note': defaultNote,
      'is_favorite': isFavorite ? 1 : 0,
      'use_count': useCount,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SmartTemplate.fromMap(Map<String, dynamic> map) {
    return SmartTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '📌',
      color: map['color'] as String? ?? '#607D8B',
      defaultThingName: map['default_thing_name'] as String?,
      defaultTags: (map['default_tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      defaultDurationMinutes: map['default_duration_minutes'] as int? ?? 30,
      defaultNote: map['default_note'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      useCount: map['use_count'] as int? ?? 0,
      category: map['category'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}

/// Template suggestion based on user behavior
class TemplateSuggestion {
  final SmartTemplate template;
  final double confidence;
  final String reason;

  TemplateSuggestion({
    required this.template,
    required this.confidence,
    required this.reason,
  });
}

/// Template usage pattern for AI suggestions
class TemplateUsagePattern {
  final String timeSlot; // morning, afternoon, evening, night
  final List<String> commonTags;
  final String? commonThingName;
  final int averageDuration;

  TemplateUsagePattern({
    required this.timeSlot,
    this.commonTags = const [],
    this.commonThingName,
    this.averageDuration = 30,
  });
}