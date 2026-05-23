import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/periodic_review/domain/periodic_review_model.dart';

/// Repository for Periodic Review data operations
class PeriodicReviewRepository {
  final Database db;

  PeriodicReviewRepository(this.db);

  /// Create a new review schedule
  Future<int> createReview(PeriodicReview review) async {
    return await db.insert('review_schedules', {
      'name': review.name,
      'type': review.type,
      'frequency': review.frequency,
      'next_review': review.nextReview.toIso8601String(),
      'last_review': review.lastReview?.toIso8601String(),
      'config': review.config,
    });
  }

  /// Update a review schedule
  Future<int> updateReview(PeriodicReview review) async {
    return await db.update(
      'review_schedules',
      {
        'name': review.name,
        'type': review.type,
        'frequency': review.frequency,
        'next_review': review.nextReview.toIso8601String(),
        'last_review': review.lastReview?.toIso8601String(),
        'config': review.config,
      },
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  /// Delete a review schedule
  Future<int> deleteReview(int id) async {
    return await db.delete(
      'review_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all review schedules
  Future<List<PeriodicReview>> getAllReviews() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'review_schedules',
      orderBy: 'next_review ASC',
    );
    return maps.map((map) => PeriodicReview.fromMap(map)).toList();
  }

  /// Get reviews by type
  Future<List<PeriodicReview>> getReviewsByType(String type) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'review_schedules',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'next_review ASC',
    );
    return maps.map((map) => PeriodicReview.fromMap(map)).toList();
  }

  /// Get due reviews
  Future<List<PeriodicReview>> getDueReviews() async {
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'review_schedules',
      where: 'next_review <= ?',
      whereArgs: [now],
      orderBy: 'next_review ASC',
    );
    return maps.map((map) => PeriodicReview.fromMap(map)).toList();
  }

  /// Mark review as completed
  Future<void> markReviewCompleted(int id) async {
    final review = await getReviewById(id);
    if (review == null) return;

    final nextReviewDate = _calculateNextReview(
      review.type,
      review.frequency,
      DateTime.now(),
    );

    await db.update(
      'review_schedules',
      {
        'last_review': DateTime.now().toIso8601String(),
        'next_review': nextReviewDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  DateTime _calculateNextReview(String type, String frequency, DateTime from) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'quarterly':
        return DateTime(from.year, from.month + 3, from.day);
      default:
        return from.add(const Duration(days: 7));
    }
  }

  /// Get review by ID
  Future<PeriodicReview?> getReviewById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'review_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PeriodicReview.fromMap(maps.first);
  }

  // ========== Review History Operations ==========

  /// Create review history entry
  Future<int> createHistoryEntry(ReviewHistory history) async {
    return await db.insert('review_history', history.toMap());
  }

  /// Get review history
  Future<List<ReviewHistory>> getHistory({int limit = 50}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'review_history',
      orderBy: 'reviewed_at DESC',
      limit: limit,
    );
    return maps.map((map) => ReviewHistory.fromMap(map)).toList();
  }

  /// Get history by type
  Future<List<ReviewHistory>> getHistoryByType(String type, {int limit = 20}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'review_history',
      where: 'schedule_type = ?',
      whereArgs: [type],
      orderBy: 'reviewed_at DESC',
      limit: limit,
    );
    return maps.map((map) => ReviewHistory.fromMap(map)).toList();
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final totalReviews = await db.rawQuery(
      'SELECT COUNT(*) as count FROM review_schedules'
    );
    final dueReviews = await db.rawQuery('''
      SELECT COUNT(*) as count FROM review_schedules 
      WHERE next_review <= ?
    ''', [DateTime.now().toIso8601String()]);
    
    final history = await db.rawQuery('''
      SELECT schedule_type, COUNT(*) as count FROM review_history 
      GROUP BY schedule_type
    ''');

    return {
      'total_schedules': (totalReviews.first['count'] as int?) ?? 0,
      'due_reviews': (dueReviews.first['count'] as int?) ?? 0,
      'history_by_type': history,
    };
  }
}