class MoodCorrelation {
  final int? id;
  final String factorType; // 'activity', 'tag', 'time', 'location'
  final String factorName;
  final double correlationStrength; // -1 to 1
  final int sampleCount;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  MoodCorrelation({
    this.id,
    required this.factorType,
    required this.factorName,
    this.correlationStrength = 0,
    this.sampleCount = 0,
    this.lastUpdated,
    required this.createdAt,
  });

  String get strengthLabel {
    final abs = correlationStrength.abs();
    if (abs < 0.2) return '无关联';
    if (abs < 0.4) return '弱关联';
    if (abs < 0.6) return '中等关联';
    if (abs < 0.8) return '强关联';
    return '非常强关联';
  }

  bool get isPositive => correlationStrength > 0;
  bool get isNegative => correlationStrength < 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'factor_type': factorType,
      'factor_name': factorName,
      'correlation_strength': correlationStrength,
      'sample_count': sampleCount,
      'last_updated': lastUpdated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodCorrelation.fromMap(Map<String, dynamic> map) {
    return MoodCorrelation(
      id: map['id'] as int?,
      factorType: map['factor_type'] as String,
      factorName: map['factor_name'] as String,
      correlationStrength: (map['correlation_strength'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sample_count'] as int? ?? 0,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}