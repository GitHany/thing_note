import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/goal_review/data/goal_review_repository.dart';
import 'package:thing_note/features/goal_review/domain/goal_review.dart';

final goalReviewRepositoryProvider = Provider((ref) => GoalReviewRepository(ref));

final allReviewsProvider = FutureProvider<List<GoalReview>>((ref) async {
  final repo = ref.read(goalReviewRepositoryProvider);
  return repo.getAllReviews();
});

final recentReviewsProvider = FutureProvider<List<GoalReview>>((ref) async {
  final repo = ref.read(goalReviewRepositoryProvider);
  return repo.getRecentReviews();
});

final reviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(goalReviewRepositoryProvider);
  return repo.getReviewStats();
});