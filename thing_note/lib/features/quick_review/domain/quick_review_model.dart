class QuickReviewCard {
  final int? id;
  final String front;
  final String back;
  final String? category;
  final String? source;
  final int? linkedRecordId;
  final double easeFactor;
  final int intervalDays;
  final String? nextReviewAt;
  final int reviewCount;
  final String createdAt;
  final String updatedAt;

  QuickReviewCard({
    this.id,
    required this.front,
    required this.back,
    this.category,
    this.source,
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
    return DateTime.parse(nextReviewAt!).isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'category': category,
      'source': source,
      'linked_record_id': linkedRecordId,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'next_review_at': nextReviewAt,
      'review_count': reviewCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory QuickReviewCard.fromMap(Map<String, dynamic> map) {
    return QuickReviewCard(
      id: map['id'] as int?,
      front: map['front'] as String,
      back: map['back'] as String,
      category: map['category'] as String?,
      source: map['source'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: map['interval_days'] as int? ?? 1,
      nextReviewAt: map['next_review_at'] as String?,
      reviewCount: map['review_count'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  QuickReviewCard copyWith({
    int? id,
    String? front,
    String? back,
    String? category,
    String? source,
    int? linkedRecordId,
    double? easeFactor,
    int? intervalDays,
    String? nextReviewAt,
    int? reviewCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return QuickReviewCard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      category: category ?? this.category,
      source: source ?? this.source,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CardReview {
  final int? id;
  final int cardId;
  final String reviewedAt;
  final int quality;
  final double easeFactor;
  final int intervalDays;

  CardReview({
    this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.quality,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'reviewed_at': reviewedAt,
      'quality': quality,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
    };
  }

  factory CardReview.fromMap(Map<String, dynamic> map) {
    return CardReview(
      id: map['id'] as int?,
      cardId: map['card_id'] as int,
      reviewedAt: map['reviewed_at'] as String,
      quality: map['quality'] as int? ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: map['interval_days'] as int? ?? 1,
    );
  }
}