import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/goal_review/domain/goal_review.dart';

class GoalReviewRepository {
  final Ref _ref;

  GoalReviewRepository(this._ref);

  Future<List<GoalReview>> getAllReviews() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'goal_reviews',
      orderBy: 'review_date DESC',
    );
    return result.map((e) => GoalReview.fromMap(e)).toList();
  }

  Future<List<GoalReview>> getReviewsByGoal(int goalId) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'goal_reviews',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'review_date DESC',
    );
    return result.map((e) => GoalReview.fromMap(e)).toList();
  }

  Future<List<GoalReview>> getRecentReviews({int limit = 10}) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'goal_reviews',
      orderBy: 'review_date DESC',
      limit: limit,
    );
    return result.map((e) => GoalReview.fromMap(e)).toList();
  }

  Future<int> insertReview(GoalReview review) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('goal_reviews', review.toMap()..remove('id'));
  }

  Future<int> deleteReview(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('goal_reviews', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getReviewStats() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_reviews,
        AVG(progress_after - progress_before) as avg_progress_change,
        MAX(progress_after - progress_before) as max_progress_change
      FROM goal_reviews
    ''');

    if (result.isEmpty) {
      return {'total_reviews': 0, 'avg_progress_change': 0.0, 'max_progress_change': 0};
    }

    return result.first;
  }
}