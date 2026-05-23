class GoalReview {
  final int? id;
  final int goalId;
  final DateTime reviewDate;
  final int progressBefore;
  final int progressAfter;
  final String? reflection;
  final String? nextSteps;
  final DateTime createdAt;

  GoalReview({
    this.id,
    required this.goalId,
    required this.reviewDate,
    this.progressBefore = 0,
    this.progressAfter = 0,
    this.reflection,
    this.nextSteps,
    required this.createdAt,
  });

  int get progressChange => progressAfter - progressBefore;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'review_date': reviewDate.toIso8601String().split('T')[0],
      'progress_before': progressBefore,
      'progress_after': progressAfter,
      'reflection': reflection,
      'next_steps': nextSteps,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalReview.fromMap(Map<String, dynamic> map) {
    return GoalReview(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      reviewDate: DateTime.parse(map['review_date'] as String),
      progressBefore: map['progress_before'] as int? ?? 0,
      progressAfter: map['progress_after'] as int? ?? 0,
      reflection: map['reflection'] as String?,
      nextSteps: map['next_steps'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}