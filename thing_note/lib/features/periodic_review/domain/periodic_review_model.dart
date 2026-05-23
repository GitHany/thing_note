/// Periodic Review model
class PeriodicReview {
  final int? id;
  final String name;
  final String type; // daily, weekly, monthly
  final String frequency;
  final DateTime nextReview;
  final DateTime? lastReview;
  final String? config;
  final DateTime createdAt;

  PeriodicReview({
    this.id,
    required this.name,
    required this.type,
    required this.frequency,
    required this.nextReview,
    this.lastReview,
    this.config,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDue => DateTime.now().isAfter(nextReview);

  int get daysUntilDue => nextReview.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'frequency': frequency,
      'next_review': nextReview.toIso8601String(),
      'last_review': lastReview?.toIso8601String(),
      'config': config,
    };
  }

  factory PeriodicReview.fromMap(Map<String, dynamic> map) {
    return PeriodicReview(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      frequency: map['frequency'] as String,
      nextReview: DateTime.parse(map['next_review'] as String),
      lastReview: map['last_review'] != null 
          ? DateTime.parse(map['last_review'] as String) 
          : null,
      config: map['config'] as String?,
    );
  }
}

/// Review History model
class ReviewHistory {
  final int? id;
  final String scheduleType;
  final String? summary;
  final int completedItems;
  final int pendingItems;
  final String? notes;
  final DateTime reviewedAt;

  ReviewHistory({
    this.id,
    required this.scheduleType,
    this.summary,
    this.completedItems = 0,
    this.pendingItems = 0,
    this.notes,
    DateTime? reviewedAt,
  }) : reviewedAt = reviewedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_type': scheduleType,
      'summary': summary,
      'completed_items': completedItems,
      'pending_items': pendingItems,
      'notes': notes,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }

  factory ReviewHistory.fromMap(Map<String, dynamic> map) {
    return ReviewHistory(
      id: map['id'] as int?,
      scheduleType: map['schedule_type'] as String,
      summary: map['summary'] as String?,
      completedItems: map['completed_items'] as int? ?? 0,
      pendingItems: map['pending_items'] as int? ?? 0,
      notes: map['notes'] as String?,
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
    );
  }
}