// Pattern Recognition Engine Models
// 模式识别引擎功能 - 从数据中发现有意义的模式

class RecognizedPattern {
  final int? id;
  final String patternType; // 'temporal', 'behavioral', 'contextual', 'sequential'
  final String name;
  final String description;
  final double confidenceScore; // 0-1
  final int occurrences;
  final Map<String, dynamic> data;
  final List<String> implications;
  final DateTime lastDetected;
  final DateTime createdAt;

  RecognizedPattern({
    this.id,
    required this.patternType,
    required this.name,
    required this.description,
    this.confidenceScore = 0,
    this.occurrences = 0,
    required this.data,
    required this.implications,
    required this.lastDetected,
    required this.createdAt,
  });

  String get confidenceLabel {
    if (confidenceScore >= 0.9) return '非常确定';
    if (confidenceScore >= 0.7) return '确定';
    if (confidenceScore >= 0.5) return '中等';
    if (confidenceScore >= 0.3) return '不确定';
    return '推测';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pattern_type': patternType,
      'name': name,
      'description': description,
      'confidence_score': confidenceScore,
      'occurrences': occurrences,
      'data': data.entries.map((e) => '${e.key}:${e.value}').join(','),
      'implications': implications.join('|||'),
      'last_detected': lastDetected.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecognizedPattern.fromMap(Map<String, dynamic> map) {
    final implicationsStr = map['implications'] as String? ?? '';
    return RecognizedPattern(
      id: map['id'] as int?,
      patternType: map['pattern_type'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      occurrences: map['occurrences'] as int? ?? 0,
      data: {},
      implications: implicationsStr.isEmpty ? [] : implicationsStr.split('|||'),
      lastDetected: DateTime.parse(map['last_detected'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PatternRule {
  final int? id;
  final String name;
  final String patternType;
  final String condition;
  final String action;
  final bool isEnabled;
  final int triggerCount;
  final DateTime createdAt;

  PatternRule({
    this.id,
    required this.name,
    required this.patternType,
    required this.condition,
    required this.action,
    this.isEnabled = true,
    this.triggerCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pattern_type': patternType,
      'condition': condition,
      'action': action,
      'is_enabled': isEnabled ? 1 : 0,
      'trigger_count': triggerCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PatternRule.fromMap(Map<String, dynamic> map) {
    return PatternRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      patternType: map['pattern_type'] as String,
      condition: map['condition'] as String,
      action: map['action'] as String,
      isEnabled: (map['is_enabled'] as int?) == 1,
      triggerCount: map['trigger_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PatternInsight {
  final int? id;
  final String category; // 'productivity', 'health', 'social', 'learning'
  final String title;
  final String content;
  final double importanceScore; // 0-1
  final List<String> actionItems;
  final bool isRead;
  final DateTime generatedAt;

  PatternInsight({
    this.id,
    required this.category,
    required this.title,
    required this.content,
    this.importanceScore = 0.5,
    required this.actionItems,
    this.isRead = false,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'content': content,
      'importance_score': importanceScore,
      'action_items': actionItems.join('|||'),
      'is_read': isRead ? 1 : 0,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory PatternInsight.fromMap(Map<String, dynamic> map) {
    final actionItemsStr = map['action_items'] as String? ?? '';
    return PatternInsight(
      id: map['id'] as int?,
      category: map['category'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      importanceScore: (map['importance_score'] as num?)?.toDouble() ?? 0.5,
      actionItems: actionItemsStr.isEmpty ? [] : actionItemsStr.split('|||'),
      isRead: (map['is_read'] as int?) == 1,
      generatedAt: DateTime.parse(map['generated_at'] as String),
    );
  }
}