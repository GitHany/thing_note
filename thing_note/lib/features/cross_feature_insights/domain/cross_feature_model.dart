/// Cross Feature Insight model
class CrossFeatureInsight {
  final int? id;
  final String insightType; // mood_productivity, habit_goal, sleep_performance, location_preference
  final String title;
  final String description;
  final double confidence;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  CrossFeatureInsight({
    this.id,
    required this.insightType,
    required this.title,
    required this.description,
    required this.confidence,
    required this.data,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'insight_type': insightType,
      'title': title,
      'description': description,
      'confidence': confidence,
      'data': data.toString(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory CrossFeatureInsight.fromMap(Map<String, dynamic> map) {
    return CrossFeatureInsight(
      id: map['id'] as int?,
      insightType: map['insight_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      data: {},
      generatedAt: DateTime.parse(map['generated_at'] as String),
    );
  }
}

/// Cross Feature Analysis Result
class CrossFeatureAnalysis {
  final List<CrossFeatureInsight> insights;
  final Map<String, double> correlations;
  final List<String> patterns;
  final Map<String, dynamic> recommendations;

  CrossFeatureAnalysis({
    required this.insights,
    required this.correlations,
    required this.patterns,
    required this.recommendations,
  });

  factory CrossFeatureAnalysis.empty() {
    return CrossFeatureAnalysis(
      insights: [],
      correlations: {},
      patterns: [],
      recommendations: {},
    );
  }
}