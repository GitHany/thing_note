class Flashcard {
  final int? id;
  final String front;
  final String back;
  final String? category;
  final int? linkedRecordId;
  final double easeFactor;
  final int intervalDays;
  final DateTime? nextReviewAt;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    this.id,
    required this.front,
    required this.back,
    this.category,
    this.linkedRecordId,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.nextReviewAt,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDueForReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'category': category,
      'linked_record_id': linkedRecordId,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'next_review_at': nextReviewAt?.toIso8601String(),
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as int?,
      front: map['front'] as String,
      back: map['back'] as String,
      category: map['category'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      easeFactor: map['ease_factor'] as double? ?? 2.5,
      intervalDays: map['interval_days'] as int? ?? 1,
      nextReviewAt: map['next_review_at'] != null 
          ? DateTime.parse(map['next_review_at'] as String) 
          : null,
      reviewCount: map['review_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Flashcard copyWith({
    int? id,
    String? front,
    String? back,
    String? category,
    int? linkedRecordId,
    double? easeFactor,
    int? intervalDays,
    DateTime? nextReviewAt,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      category: category ?? this.category,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// SM-2 algorithm for spaced repetition
  /// quality: 0-5 (0=complete blackout, 5=perfect response)
  Flashcard applyReview(int quality) {
    double newEaseFactor = easeFactor;
    int newInterval = intervalDays;

    if (quality < 3) {
      // Reset interval on poor recall
      newInterval = 1;
    } else {
      // Adjust ease factor based on quality
      newEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < 1.3) newEaseFactor = 1.3;

      // Calculate new interval
      if (reviewCount == 0) {
        newInterval = 1;
      } else if (reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (intervalDays * newEaseFactor).round();
      }
    }

    return copyWith(
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
      nextReviewAt: DateTime.now().add(Duration(days: newInterval)),
      reviewCount: reviewCount + 1,
      updatedAt: DateTime.now(),
    );
  }
}

class FlashcardReview {
  final int? id;
  final int flashcardId;
  final DateTime reviewedAt;
  final int quality;
  final double easeFactor;
  final int intervalDays;

  FlashcardReview({
    this.id,
    required this.flashcardId,
    required this.reviewedAt,
    required this.quality,
    required this.easeFactor,
    required this.intervalDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flashcard_id': flashcardId,
      'reviewed_at': reviewedAt.toIso8601String(),
      'quality': quality,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
    };
  }

  factory FlashcardReview.fromMap(Map<String, dynamic> map) {
    return FlashcardReview(
      id: map['id'] as int?,
      flashcardId: map['flashcard_id'] as int,
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
      quality: map['quality'] as int,
      easeFactor: map['ease_factor'] as double,
      intervalDays: map['interval_days'] as int,
    );
  }
}