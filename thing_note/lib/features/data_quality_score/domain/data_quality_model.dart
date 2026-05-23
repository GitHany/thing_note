class DataQualityScore {
  final int? id;
  final String date;
  final double completenessScore;
  final double continuityScore;
  final double depthScore;
  final double relevanceScore;
  final double overallScore;
  final List<String> suggestions;
  final DateTime createdAt;

  DataQualityScore({
    this.id,
    required this.date,
    this.completenessScore = 0,
    this.continuityScore = 0,
    this.depthScore = 0,
    this.relevanceScore = 0,
    this.overallScore = 0,
    this.suggestions = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'completeness_score': completenessScore,
      'continuity_score': continuityScore,
      'depth_score': depthScore,
      'relevance_score': relevanceScore,
      'overall_score': overallScore,
      'suggestions': suggestions.join('|'),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DataQualityScore.fromMap(Map<String, dynamic> map) {
    return DataQualityScore(
      id: map['id'],
      date: map['date'],
      completenessScore: (map['completeness_score'] ?? 0).toDouble(),
      continuityScore: (map['continuity_score'] ?? 0).toDouble(),
      depthScore: (map['depth_score'] ?? 0).toDouble(),
      relevanceScore: (map['relevance_score'] ?? 0).toDouble(),
      overallScore: (map['overall_score'] ?? 0).toDouble(),
      suggestions: (map['suggestions'] as String?)?.split('|').where((e) => e.isNotEmpty).toList() ?? [],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get overallGrade {
    if (overallScore >= 90) return 'A+';
    if (overallScore >= 80) return 'A';
    if (overallScore >= 70) return 'B';
    if (overallScore >= 60) return 'C';
    return 'D';
  }

  DataQualityScore copyWith({
    int? id,
    String? date,
    double? completenessScore,
    double? continuityScore,
    double? depthScore,
    double? relevanceScore,
    double? overallScore,
    List<String>? suggestions,
    DateTime? createdAt,
  }) {
    return DataQualityScore(
      id: id ?? this.id,
      date: date ?? this.date,
      completenessScore: completenessScore ?? this.completenessScore,
      continuityScore: continuityScore ?? this.continuityScore,
      depthScore: depthScore ?? this.depthScore,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      overallScore: overallScore ?? this.overallScore,
      suggestions: suggestions ?? this.suggestions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}