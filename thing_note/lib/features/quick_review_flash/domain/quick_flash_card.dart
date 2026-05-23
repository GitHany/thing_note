/// 快速闪卡数据模型
class QuickFlashCard {
  final int? id;
  final String front;
  final String back;
  final String? category;
  final String? source;
  final int difficulty; // 1-5
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final double easeFactor;
  final int intervalDays;
  final int reviewCount;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuickFlashCard({
    this.id,
    required this.front,
    required this.back,
    this.category,
    this.source,
    this.difficulty = 2,
    this.lastReviewed,
    this.nextReview,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.reviewCount = 0,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDue {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }

  /// SM-2 算法计算下次复习间隔
  QuickFlashCard applyReview(int quality) {
    // quality: 0-忘记, 1-困难回忆, 2-一般, 3-良好, 4-简单, 5-完美
    double newEase = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    newEase = newEase.clamp(1.3, 2.5);

    int newInterval;
    if (quality < 3) {
      newInterval = 1;
    } else if (reviewCount == 0) {
      newInterval = 1;
    } else if (reviewCount == 1) {
      newInterval = 6;
    } else {
      newInterval = (intervalDays * newEase).round();
    }

    return copyWith(
      easeFactor: newEase,
      intervalDays: newInterval,
      reviewCount: reviewCount + 1,
      lastReviewed: DateTime.now(),
      nextReview: DateTime.now().add(Duration(days: newInterval)),
      updatedAt: DateTime.now(),
    );
  }

  QuickFlashCard copyWith({
    int? id,
    String? front,
    String? back,
    String? category,
    String? source,
    int? difficulty,
    DateTime? lastReviewed,
    DateTime? nextReview,
    double? easeFactor,
    int? intervalDays,
    int? reviewCount,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuickFlashCard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      category: category ?? this.category,
      source: source ?? this.source,
      difficulty: difficulty ?? this.difficulty,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'front': front,
      'back': back,
      'category': category,
      'source': source,
      'difficulty': difficulty,
      'last_reviewed': lastReviewed?.toIso8601String(),
      'next_review': nextReview?.toIso8601String(),
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'review_count': reviewCount,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory QuickFlashCard.fromMap(Map<String, dynamic> map) {
    return QuickFlashCard(
      id: map['id'] as int?,
      front: map['front'] as String,
      back: map['back'] as String,
      category: map['category'] as String?,
      source: map['source'] as String?,
      difficulty: map['difficulty'] as int? ?? 2,
      lastReviewed: map['last_reviewed'] != null
          ? DateTime.parse(map['last_reviewed'] as String)
          : null,
      nextReview: map['next_review'] != null
          ? DateTime.parse(map['next_review'] as String)
          : null,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: map['interval_days'] as int? ?? 1,
      reviewCount: map['review_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class FlashCardReview {
  final int? id;
  final int cardId;
  final DateTime reviewedAt;
  final int quality;
  final double easeFactor;
  final int intervalDays;

  const FlashCardReview({
    this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.quality,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'card_id': cardId,
      'reviewed_at': reviewedAt.toIso8601String(),
      'quality': quality,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
    };
  }

  factory FlashCardReview.fromMap(Map<String, dynamic> map) {
    return FlashCardReview(
      id: map['id'] as int?,
      cardId: map['card_id'] as int,
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
      quality: map['quality'] as int,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: map['interval_days'] as int? ?? 1,
    );
  }
}
