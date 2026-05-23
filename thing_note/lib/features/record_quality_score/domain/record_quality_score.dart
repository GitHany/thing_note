// Record Quality Score Models
// 记录质量评分功能 - 评估每条记录的质量并提供改进建议

class RecordQualityScore {
  final int? id;
  final int recordId;
  final int totalScore; // 0-100
  final int completenessScore; // 0-25
  final int detailScore; // 0-25
  final int consistencyScore; // 0-25
  final int timelinessScore; // 0-25
  final List<String> suggestions;
  final DateTime evaluatedAt;

  RecordQualityScore({
    this.id,
    required this.recordId,
    required this.totalScore,
    required this.completenessScore,
    required this.detailScore,
    required this.consistencyScore,
    required this.timelinessScore,
    required this.suggestions,
    required this.evaluatedAt,
  });

  String get qualityLevel {
    if (totalScore >= 90) return '优秀';
    if (totalScore >= 75) return '良好';
    if (totalScore >= 60) return '一般';
    if (totalScore >= 40) return '待改进';
    return '需完善';
  }

  String get qualityEmoji {
    if (totalScore >= 90) return '🌟';
    if (totalScore >= 75) return '✨';
    if (totalScore >= 60) return '👍';
    if (totalScore >= 40) return '💡';
    return '📝';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'total_score': totalScore,
      'completeness_score': completenessScore,
      'detail_score': detailScore,
      'consistency_score': consistencyScore,
      'timeliness_score': timelinessScore,
      'suggestions': suggestions.join('|||'),
      'evaluated_at': evaluatedAt.toIso8601String(),
    };
  }

  factory RecordQualityScore.fromMap(Map<String, dynamic> map) {
    final suggestionsStr = map['suggestions'] as String? ?? '';
    return RecordQualityScore(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      totalScore: map['total_score'] as int,
      completenessScore: map['completeness_score'] as int,
      detailScore: map['detail_score'] as int,
      consistencyScore: map['consistency_score'] as int,
      timelinessScore: map['timeliness_score'] as int,
      suggestions: suggestionsStr.isEmpty ? [] : suggestionsStr.split('|||'),
      evaluatedAt: DateTime.parse(map['evaluated_at'] as String),
    );
  }
}

class QualityCriteria {
  final String name;
  final String description;
  final int maxScore;
  final String icon;

  const QualityCriteria({
    required this.name,
    required this.description,
    required this.maxScore,
    required this.icon,
  });

  static const completeness = QualityCriteria(
    name: '完整性',
    description: '记录是否包含必要的信息',
    maxScore: 25,
    icon: '📋',
  );

  static const detail = QualityCriteria(
    name: '详细性',
    description: '记录的描述是否详细',
    maxScore: 25,
    icon: '📝',
  );

  static const consistency = QualityCriteria(
    name: '一致性',
    description: '记录格式和内容是否一致',
    maxScore: 25,
    icon: '🔄',
  );

  static const timeliness = QualityCriteria(
    name: '时效性',
    description: '记录是否及时',
    maxScore: 25,
    icon: '⏰',
  );
}

class QualityBenchmark {
  final int? id;
  final String period; // 'daily', 'weekly', 'monthly'
  final double averageScore;
  final int totalRecords;
  final DateTime calculatedAt;

  QualityBenchmark({
    this.id,
    required this.period,
    required this.averageScore,
    required this.totalRecords,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period,
      'average_score': averageScore,
      'total_records': totalRecords,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory QualityBenchmark.fromMap(Map<String, dynamic> map) {
    return QualityBenchmark(
      id: map['id'] as int?,
      period: map['period'] as String,
      averageScore: (map['average_score'] as num).toDouble(),
      totalRecords: map['total_records'] as int,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
    );
  }
}