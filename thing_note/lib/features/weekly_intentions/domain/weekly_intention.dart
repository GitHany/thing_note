class WeeklyIntention {
  final int? id;
  final String weekStart;
  final String? weekTheme;
  final String intentions;
  final String? dailyAdjustments;
  final String? midWeekReview;
  final String? weekReview;
  final int themeContinuation;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklyIntention({
    this.id,
    required this.weekStart,
    this.weekTheme,
    this.intentions = '',
    this.dailyAdjustments,
    this.midWeekReview,
    this.weekReview,
    this.themeContinuation = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'week_start': weekStart,
      'week_theme': weekTheme,
      'intentions': intentions,
      'daily_adjustments': dailyAdjustments,
      'mid_week_review': midWeekReview,
      'week_review': weekReview,
      'theme_continuation': themeContinuation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WeeklyIntention.fromMap(Map<String, dynamic> map) {
    return WeeklyIntention(
      id: map['id'] as int?,
      weekStart: map['week_start'] as String,
      weekTheme: map['week_theme'] as String?,
      intentions: map['intentions'] as String? ?? '',
      dailyAdjustments: map['daily_adjustments'] as String?,
      midWeekReview: map['mid_week_review'] as String?,
      weekReview: map['week_review'] as String?,
      themeContinuation: map['theme_continuation'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  List<String> get intentionList =>
      intentions.split('\n').where((s) => s.trim().isNotEmpty).toList();

  WeeklyIntention copyWith({
    int? id,
    String? weekStart,
    String? weekTheme,
    String? intentions,
    String? dailyAdjustments,
    String? midWeekReview,
    String? weekReview,
    int? themeContinuation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyIntention(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      weekTheme: weekTheme ?? this.weekTheme,
      intentions: intentions ?? this.intentions,
      dailyAdjustments: dailyAdjustments ?? this.dailyAdjustments,
      midWeekReview: midWeekReview ?? this.midWeekReview,
      weekReview: weekReview ?? this.weekReview,
      themeContinuation: themeContinuation ?? this.themeContinuation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get week start date (Monday)
  DateTime get weekStartDate => DateTime.parse(weekStart);

  /// Get week end date (Sunday)
  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));
}