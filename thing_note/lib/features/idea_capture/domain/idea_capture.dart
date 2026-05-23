class IdeaCapture {
  final int? id;
  final String title;
  final String? content;
  final String? category;
  final bool isConverted;
  final String? convertedToType;
  final int? convertedToId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  IdeaCapture({
    this.id,
    required this.title,
    this.content,
    this.category,
    this.isConverted = false,
    this.convertedToType,
    this.convertedToId,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'is_converted': isConverted ? 1 : 0,
      'converted_to_type': convertedToType,
      'converted_to_id': convertedToId,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory IdeaCapture.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return IdeaCapture(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String?,
      category: map['category'] as String?,
      isConverted: (map['is_converted'] as int?) == 1,
      convertedToType: map['converted_to_type'] as String?,
      convertedToId: map['converted_to_id'] as int?,
      tags: tagsStr != null && tagsStr.isNotEmpty
          ? tagsStr.split(',')
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  IdeaCapture copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    bool? isConverted,
    String? convertedToType,
    int? convertedToId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdeaCapture(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isConverted: isConverted ?? this.isConverted,
      convertedToType: convertedToType ?? this.convertedToType,
      convertedToId: convertedToId ?? this.convertedToId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}