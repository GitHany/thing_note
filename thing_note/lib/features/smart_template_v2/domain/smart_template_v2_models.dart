/// Smart Template V2 - 智能记录模板
/// 基于用户习惯的智能模板推荐系统
library;

/// 模板使用历史记录
class TemplateUsage {
  final int templateId;
  final String templateName;
  final DateTime usedAt;
  final String? context; // 使用场景描述

  TemplateUsage({
    required this.templateId,
    required this.templateName,
    required this.usedAt,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'template_id': templateId,
      'template_name': templateName,
      'used_at': usedAt.toIso8601String(),
      'context': context,
    };
  }

  factory TemplateUsage.fromMap(Map<String, dynamic> map) {
    return TemplateUsage(
      templateId: map['template_id'] as int,
      templateName: map['template_name'] as String,
      usedAt: DateTime.parse(map['used_at'] as String),
      context: map['context'] as String?,
    );
  }
}

/// 模板推荐结果
class TemplateRecommendation {
  final int templateId;
  final String templateName;
  final double confidence; // 0.0 - 1.0
  final String reason;
  final String? category;
  final List<String> suggestedTags;
  final int useCount;

  TemplateRecommendation({
    required this.templateId,
    required this.templateName,
    required this.confidence,
    required this.reason,
    this.category,
    this.suggestedTags = const [],
    this.useCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'template_id': templateId,
      'template_name': templateName,
      'confidence': confidence,
      'reason': reason,
      'category': category,
      'suggested_tags': suggestedTags.join(','),
      'use_count': useCount,
    };
  }

  factory TemplateRecommendation.fromMap(Map<String, dynamic> map) {
    final tags = (map['suggested_tags'] as String?) ?? '';
    return TemplateRecommendation(
      templateId: map['template_id'] as int,
      templateName: map['template_name'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      reason: map['reason'] as String,
      category: map['category'] as String?,
      suggestedTags: tags.isEmpty ? [] : tags.split(','),
      useCount: (map['use_count'] as int?) ?? 0,
    );
  }
}

/// 使用模式分析
class UsagePattern {
  final String timeOfDay; // morning, afternoon, evening, night
  final String dayOfWeek;
  final String? location;
  final List<String> commonTags;
  final List<String> commonThingNames;
  final int avgRecordCount;

  UsagePattern({
    required this.timeOfDay,
    required this.dayOfWeek,
    this.location,
    this.commonTags = const [],
    this.commonThingNames = const [],
    this.avgRecordCount = 0,
  });
}

/// 模板创建请求
class TemplateCreateRequest {
  final String name;
  final String? category;
  final String? description;
  final String? defaultThingName;
  final List<String> defaultTags;
  final int defaultDurationMinutes;
  final bool isFavorite;
  final String? icon;

  TemplateCreateRequest({
    required this.name,
    this.category,
    this.description,
    this.defaultThingName,
    this.defaultTags = const [],
    this.defaultDurationMinutes = 0,
    this.isFavorite = false,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'default_thing_name': defaultThingName,
      'default_tags': defaultTags.join(','),
      'default_duration': defaultDurationMinutes,
      'is_favorite': isFavorite ? 1 : 0,
      'icon': icon,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}