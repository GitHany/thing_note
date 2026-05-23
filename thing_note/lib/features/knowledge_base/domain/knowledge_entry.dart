class KnowledgeEntry {
  final int? id;
  final String title;
  final String content;
  final String? category;
  final String? tags;
  final String? source;
  final int useCount;
  final int isFavorite;
  final String? linkedRecordIds;
  final String createdAt;
  final String updatedAt;

  KnowledgeEntry({
    this.id,
    required this.title,
    required this.content,
    this.category,
    this.tags,
    this.source,
    this.useCount = 0,
    this.isFavorite = 0,
    this.linkedRecordIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'source': source,
      'use_count': useCount,
      'is_favorite': isFavorite,
      'linked_record_ids': linkedRecordIds,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory KnowledgeEntry.fromMap(Map<String, dynamic> map) {
    return KnowledgeEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      tags: map['tags'] as String?,
      source: map['source'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      isFavorite: map['is_favorite'] as int? ?? 0,
      linkedRecordIds: map['linked_record_ids'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  KnowledgeEntry copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? tags,
    String? source,
    int? useCount,
    int? isFavorite,
    String? linkedRecordIds,
    String? createdAt,
    String? updatedAt,
  }) {
    return KnowledgeEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      useCount: useCount ?? this.useCount,
      isFavorite: isFavorite ?? this.isFavorite,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  static List<String> get categories => [
    '技术',
    '生活',
    '工作',
    '健康',
    '学习',
    '其他',
  ];
}