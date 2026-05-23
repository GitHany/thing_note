/// 标签推荐数据模型
enum RecommendationType {
  keyword,
  time,
  frequency,
  thingName,
  cooccurrence,
}

extension RecommendationTypeExtension on RecommendationType {
  String get displayName {
    switch (this) {
      case RecommendationType.keyword:
        return '关键词匹配';
      case RecommendationType.time:
        return '时间模式';
      case RecommendationType.frequency:
        return '使用频率';
      case RecommendationType.thingName:
        return '事件名称';
      case RecommendationType.cooccurrence:
        return '标签关联';
    }
  }
}

class TagRecommendation {
  final String tagName;
  final String reason;
  final double score;
  final RecommendationType type;

  const TagRecommendation({
    required this.tagName,
    required this.reason,
    required this.score,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'tag_name': tagName,
      'reason': reason,
      'score': score,
      'type': type.name,
    };
  }

  factory TagRecommendation.fromMap(Map<String, dynamic> map) {
    return TagRecommendation(
      tagName: map['tag_name'] as String,
      reason: map['reason'] as String,
      score: (map['score'] as num).toDouble(),
      type: RecommendationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RecommendationType.keyword,
      ),
    );
  }
}