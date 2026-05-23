import 'dart:convert';

class BatchTagItem {
  final int? id;
  final int recordId;
  final String tagName;
  final DateTime addedAt;

  BatchTagItem({
    this.id,
    required this.recordId,
    required this.tagName,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'tag_name': tagName,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory BatchTagItem.fromMap(Map<String, dynamic> map) {
    return BatchTagItem(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      tagName: map['tag_name'] as String,
      addedAt: DateTime.parse(map['added_at'] as String),
    );
  }
}

class BatchTagOperation {
  final int? id;
  final String operationType; // add, remove, replace
  final List<int> recordIds;
  final List<String> tags;
  final DateTime performedAt;

  BatchTagOperation({
    this.id,
    required this.operationType,
    required this.recordIds,
    required this.tags,
    required this.performedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'operation_type': operationType,
      'record_ids': jsonEncode(recordIds),
      'tags': jsonEncode(tags),
      'performed_at': performedAt.toIso8601String(),
    };
  }

  factory BatchTagOperation.fromMap(Map<String, dynamic> map) {
    return BatchTagOperation(
      id: map['id'] as int?,
      operationType: map['operation_type'] as String,
      recordIds: List<int>.from(jsonDecode(map['record_ids'] as String)),
      tags: List<String>.from(jsonDecode(map['tags'] as String)),
      performedAt: DateTime.parse(map['performed_at'] as String),
    );
  }
}

class TagStatistics {
  final String tagName;
  final int usageCount;
  final DateTime? lastUsed;

  TagStatistics({
    required this.tagName,
    required this.usageCount,
    this.lastUsed,
  });
}

class BatchTagConfig {
  final bool autoSuggestTags;
  final bool preserveExistingTags;
  final bool caseSensitive;
  final List<String> favoriteTags;

  BatchTagConfig({
    this.autoSuggestTags = true,
    this.preserveExistingTags = true,
    this.caseSensitive = false,
    this.favoriteTags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'auto_suggest_tags': autoSuggestTags ? 1 : 0,
      'preserve_existing_tags': preserveExistingTags ? 1 : 0,
      'case_sensitive': caseSensitive ? 1 : 0,
      'favorite_tags': jsonEncode(favoriteTags),
    };
  }

  factory BatchTagConfig.fromMap(Map<String, dynamic> map) {
    return BatchTagConfig(
      autoSuggestTags: (map['auto_suggest_tags'] as int?) == 1,
      preserveExistingTags: (map['preserve_existing_tags'] as int?) == 1,
      caseSensitive: (map['case_sensitive'] as int?) == 1,
      favoriteTags: List<String>.from(jsonDecode(map['favorite_tags'] as String? ?? '[]')),
    );
  }
}