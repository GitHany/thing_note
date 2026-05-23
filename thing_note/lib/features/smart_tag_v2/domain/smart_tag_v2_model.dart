class TagRecommendationHistory {
  final int? id;
  final int recordId;
  final List<String> recommendedTags;
  final List<String> selectedTags;
  final List<double> confidenceScores;
  final String modelVersion;
  final String recommendedAt;

  TagRecommendationHistory({
    this.id,
    required this.recordId,
    this.recommendedTags = const [],
    this.selectedTags = const [],
    this.confidenceScores = const [],
    this.modelVersion = 'v1',
    required this.recommendedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'recommended_tags': recommendedTags.join(','),
      'selected_tags': selectedTags.join(','),
      'confidence_scores': confidenceScores.join(','),
      'model_version': modelVersion,
      'recommended_at': recommendedAt,
    };
  }

  factory TagRecommendationHistory.fromMap(Map<String, dynamic> map) {
    return TagRecommendationHistory(
      id: map['id'],
      recordId: map['record_id'],
      recommendedTags: (map['recommended_tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      selectedTags: (map['selected_tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      confidenceScores: (map['confidence_scores'] as String?)?.split(',').map((e) => double.tryParse(e) ?? 0).toList() ?? [],
      modelVersion: map['model_version'] ?? 'v1',
      recommendedAt: map['recommended_at'],
    );
  }
}

class SmartTagConfig {
  final bool enabled;
  final int maxRecommendations;
  final bool showConfidence;
  final bool autoApplyHighConfidence;

  SmartTagConfig({
    this.enabled = true,
    this.maxRecommendations = 5,
    this.showConfidence = true,
    this.autoApplyHighConfidence = false,
  });
}