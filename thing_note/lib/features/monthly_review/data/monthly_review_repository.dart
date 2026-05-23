import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/monthly_review/domain/monthly_review_models.dart';

final monthlyReviewRepositoryProvider = Provider<MonthlyReviewRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MonthlyReviewRepository(dbAsync);
});

final monthlyReviewsProvider = StateNotifierProvider<MonthlyReviewsNotifier, AsyncValue<List<MonthlyReview>>>((ref) {
  final repository = ref.watch(monthlyReviewRepositoryProvider);
  return MonthlyReviewsNotifier(repository);
});

final currentMonthReviewProvider = FutureProvider<MonthlyReview?>((ref) async {
  final now = DateTime.now();
  final repository = ref.watch(monthlyReviewRepositoryProvider);
  return repository.getReviewByYearMonth(now.year, now.month);
});

final monthlyGoalsProvider = FutureProvider.family<List<MonthlyGoal>, ({int year, int month})>((ref, params) async {
  final repository = ref.watch(monthlyReviewRepositoryProvider);
  return repository.getGoalsByYearMonth(params.year, params.month);
});

class MonthlyReviewRepository {
  final AsyncValue<Database> _dbAsync;

  MonthlyReviewRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Review CRUD
  Future<int> insertReview(MonthlyReview review) async {
    final db = await _db;
    return db.insert('monthly_reviews', review.toMap());
  }

  Future<int> updateReview(MonthlyReview review) async {
    final db = await _db;
    return db.update('monthly_reviews', review.toMap(), where: 'id = ?', whereArgs: [review.id]);
  }

  Future<int> deleteReview(int id) async {
    final db = await _db;
    return db.delete('monthly_reviews', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MonthlyReview>> getAllReviews() async {
    final db = await _db;
    final maps = await db.query('monthly_reviews', orderBy: 'year DESC, month DESC');
    return maps.map((m) => MonthlyReview.fromMap(m)).toList();
  }

  Future<MonthlyReview?> getReviewById(int id) async {
    final db = await _db;
    final maps = await db.query('monthly_reviews', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return MonthlyReview.fromMap(maps.first);
  }

  Future<MonthlyReview?> getReviewByYearMonth(int year, int month) async {
    final db = await _db;
    final maps = await db.query(
      'monthly_reviews',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    if (maps.isEmpty) return null;
    return MonthlyReview.fromMap(maps.first);
  }

  // Goal CRUD
  Future<int> insertGoal(MonthlyGoal goal) async {
    final db = await _db;
    return db.insert('monthly_goals', goal.toMap());
  }

  Future<int> updateGoal(MonthlyGoal goal) async {
    final db = await _db;
    return db.update('monthly_goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<int> deleteGoal(int id) async {
    final db = await _db;
    return db.delete('monthly_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MonthlyGoal>> getGoalsByYearMonth(int year, int month) async {
    final db = await _db;
    final maps = await db.query(
      'monthly_goals',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => MonthlyGoal.fromMap(m)).toList();
  }

  // Stats
  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final db = await _db;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Count records for the month
    final records = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records 
      WHERE occurred_at >= ? AND occurred_at <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Count completed habits
    final habits = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_logs
      WHERE completed_at >= ? AND completed_at <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'record_count': records.first['count'] ?? 0,
      'habit_count': habits.first['count'] ?? 0,
    };
  }
}

class MonthlyReviewsNotifier extends StateNotifier<AsyncValue<List<MonthlyReview>>> {
  final MonthlyReviewRepository _repository;

  MonthlyReviewsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = const AsyncValue.loading();
    try {
      final reviews = await _repository.getAllReviews();
      state = AsyncValue.data(reviews);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReview(MonthlyReview review) async {
    try {
      await _repository.insertReview(review);
      await loadReviews();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateReview(MonthlyReview review) async {
    try {
      await _repository.updateReview(review);
      await loadReviews();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReview(int id) async {
    try {
      await _repository.deleteReview(id);
      await loadReviews();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}