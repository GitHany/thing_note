class DailyScore {
  final int? id;
  final String date;
  final double productivityScore;
  final double healthScore;
  final double moodScore;
  final double socialScore;
  final double overallScore;
  final List<String>? achievements;
  final String? note;
  final DateTime createdAt;

  DailyScore({
    this.id,
    required this.date,
    this.productivityScore = 0,
    this.healthScore = 0,
    this.moodScore = 0,
    this.socialScore = 0,
    this.overallScore = 0,
    this.achievements,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get grade {
    if (overallScore >= 90) return 'A+';
    if (overallScore >= 80) return 'A';
    if (overallScore >= 70) return 'B+';
    if (overallScore >= 60) return 'B';
    if (overallScore >= 50) return 'C';
    return 'D';
  }

  String get gradeEmoji {
    if (overallScore >= 90) return '🌟';
    if (overallScore >= 80) return '✨';
    if (overallScore >= 70) return '😊';
    if (overallScore >= 60) return '🙂';
    if (overallScore >= 50) return '😐';
    return '😔';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'productivity_score': productivityScore,
      'health_score': healthScore,
      'mood_score': moodScore,
      'social_score': socialScore,
      'overall_score': overallScore,
      'achievements': achievements?.join(','),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyScore.fromMap(Map<String, dynamic> map) {
    return DailyScore(
      id: map['id'] as int?,
      date: map['date'] as String,
      productivityScore: (map['productivity_score'] as num?)?.toDouble() ?? 0,
      healthScore: (map['health_score'] as num?)?.toDouble() ?? 0,
      moodScore: (map['mood_score'] as num?)?.toDouble() ?? 0,
      socialScore: (map['social_score'] as num?)?.toDouble() ?? 0,
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0,
      achievements: (map['achievements'] as String?)?.split(',').where((s) => s.isNotEmpty).toList(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyScore copyWith({
    int? id,
    String? date,
    double? productivityScore,
    double? healthScore,
    double? moodScore,
    double? socialScore,
    double? overallScore,
    List<String>? achievements,
    String? note,
    DateTime? createdAt,
  }) {
    return DailyScore(
      id: id ?? this.id,
      date: date ?? this.date,
      productivityScore: productivityScore ?? this.productivityScore,
      healthScore: healthScore ?? this.healthScore,
      moodScore: moodScore ?? this.moodScore,
      socialScore: socialScore ?? this.socialScore,
      overallScore: overallScore ?? this.overallScore,
      achievements: achievements ?? this.achievements,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}