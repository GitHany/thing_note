/// 智能分类助手 - Smart Classifier
/// 基于内容的自动分类建议
library;

/// 分类建议
class ClassificationSuggestion {
  final int recordId;
  final String? suggestedThingName;
  final List<String> suggestedTags;
  final double confidence;
  final String reason;
  final ClassificationType type;

  ClassificationSuggestion({
    required this.recordId,
    this.suggestedThingName,
    this.suggestedTags = const [],
    required this.confidence,
    required this.reason,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'suggested_thing_name': suggestedThingName,
      'suggested_tags': suggestedTags.join(','),
      'confidence': confidence,
      'reason': reason,
      'type': type.name,
    };
  }
}

/// 分类类型
enum ClassificationType {
  thingName, // 事情名称
  tag, // 标签
  both, // 两者都有
}

/// 内容特征
class ContentFeature {
  final List<String> keywords;
  final List<String> entities;
  final String? timeMention; // 提到的时间
  final String? locationMention; // 提到的位置
  final int estimatedDuration;

  ContentFeature({
    this.keywords = const [],
    this.entities = const [],
    this.timeMention,
    this.locationMention,
    this.estimatedDuration = 0,
  });
}

/// 分类规则
class ClassificationRule {
  final int? id;
  final String name;
  final String pattern; // 匹配模式
  final String? assignedThingName;
  final List<String> assignedTags;
  final bool isEnabled;
  final int matchCount;

  ClassificationRule({
    this.id,
    required this.name,
    required this.pattern,
    this.assignedThingName,
    this.assignedTags = const [],
    this.isEnabled = true,
    this.matchCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pattern': pattern,
      'assigned_thing_name': assignedThingName,
      'assigned_tags': assignedTags.join(','),
      'is_enabled': isEnabled ? 1 : 0,
      'match_count': matchCount,
    };
  }

  factory ClassificationRule.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['assigned_tags'] as String? ?? '';
    return ClassificationRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      pattern: map['pattern'] as String,
      assignedThingName: map['assigned_thing_name'] as String?,
      assignedTags: tagsStr.isEmpty ? [] : tagsStr.split(','),
      isEnabled: (map['is_enabled'] as int?) == 1,
      matchCount: (map['match_count'] as int?) ?? 0,
    );
  }
}