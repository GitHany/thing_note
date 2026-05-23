// Smart Tag Merge Models
// 智能标签合并功能 - 分析相似标签并提供合并建议

class TagMergeSuggestion {
  final int? id;
  final String sourceTag;
  final String targetTag;
  final double similarityScore; // 0-1
  final int sharedRecordCount;
  final int? usageOverlapPercent;
  final String? reason;
  final bool isAutoSuggested;
  final bool isAccepted;
  final DateTime createdAt;

  TagMergeSuggestion({
    this.id,
    required this.sourceTag,
    required this.targetTag,
    this.similarityScore = 0,
    this.sharedRecordCount = 0,
    this.usageOverlapPercent,
    this.reason,
    this.isAutoSuggested = true,
    this.isAccepted = false,
    required this.createdAt,
  });

  String get similarityLabel {
    if (similarityScore >= 0.9) return '几乎相同';
    if (similarityScore >= 0.7) return '非常相似';
    if (similarityScore >= 0.5) return '相似';
    if (similarityScore >= 0.3) return '可能相关';
    return '不确定';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_tag': sourceTag,
      'target_tag': targetTag,
      'similarity_score': similarityScore,
      'shared_record_count': sharedRecordCount,
      'usage_overlap_percent': usageOverlapPercent,
      'reason': reason,
      'is_auto_suggested': isAutoSuggested ? 1 : 0,
      'is_accepted': isAccepted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TagMergeSuggestion.fromMap(Map<String, dynamic> map) {
    return TagMergeSuggestion(
      id: map['id'] as int?,
      sourceTag: map['source_tag'] as String,
      targetTag: map['target_tag'] as String,
      similarityScore: (map['similarity_score'] as num?)?.toDouble() ?? 0,
      sharedRecordCount: map['shared_record_count'] as int? ?? 0,
      usageOverlapPercent: map['usage_overlap_percent'] as int?,
      reason: map['reason'] as String?,
      isAutoSuggested: (map['is_auto_suggested'] as int?) == 1,
      isAccepted: (map['is_accepted'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class TagGroup {
  final int? id;
  final String groupName;
  final List<String> tags;
  final String? color;
  final String? icon;
  final DateTime createdAt;

  TagGroup({
    this.id,
    required this.groupName,
    required this.tags,
    this.color,
    this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_name': groupName,
      'tags': tags.join(','),
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TagGroup.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String? ?? '';
    return TagGroup(
      id: map['id'] as int?,
      groupName: map['group_name'] as String,
      tags: tagsStr.isEmpty ? [] : tagsStr.split(','),
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class TagAlias {
  final int? id;
  final String mainTag;
  final List<String> aliases;
  final DateTime createdAt;

  TagAlias({
    this.id,
    required this.mainTag,
    required this.aliases,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'main_tag': mainTag,
      'aliases': aliases.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TagAlias.fromMap(Map<String, dynamic> map) {
    final aliasesStr = map['aliases'] as String? ?? '';
    return TagAlias(
      id: map['id'] as int?,
      mainTag: map['main_tag'] as String,
      aliases: aliasesStr.isEmpty ? [] : aliasesStr.split(','),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}