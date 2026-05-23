/// Knowledge Base Entry model
class KnowledgeEntry {
  final int? id;
  final String title;
  final String content;
  final String? summary;
  final String? source;
  final int? linkedRecordId;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeEntry({
    this.id,
    required this.title,
    required this.content,
    this.summary,
    this.source,
    this.linkedRecordId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'source': source,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory KnowledgeEntry.fromMap(Map<String, dynamic> map) {
    return KnowledgeEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String?,
      source: map['source'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  KnowledgeEntry copyWith({
    int? id,
    String? title,
    String? content,
    String? summary,
    String? source,
    int? linkedRecordId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      source: source ?? this.source,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Knowledge Tag model
class KnowledgeTag {
  final int? id;
  final int knowledgeId;
  final String tag;

  KnowledgeTag({
    this.id,
    required this.knowledgeId,
    required this.tag,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'knowledge_id': knowledgeId,
      'tag': tag,
    };
  }

  factory KnowledgeTag.fromMap(Map<String, dynamic> map) {
    return KnowledgeTag(
      id: map['id'] as int?,
      knowledgeId: map['knowledge_id'] as int,
      tag: map['tag'] as String,
    );
  }
}