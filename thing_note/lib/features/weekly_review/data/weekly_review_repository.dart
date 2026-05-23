import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_review/domain/weekly_review.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final weeklyReviewRepositoryProvider = Provider<WeeklyReviewRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return WeeklyReviewRepository(dbAsync);
});

final weeklyReviewsProvider = StateNotifierProvider<WeeklyReviewsNotifier, AsyncValue<List<WeeklyReview>>>((ref) {
  final repository = ref.watch(weeklyReviewRepositoryProvider);
  return WeeklyReviewsNotifier(repository);
});

final currentWeekStatsProvider = FutureProvider<WeekStats>((ref) async {
  final repository = ref.watch(weeklyReviewRepositoryProvider);
  return repository.getWeekStats(DateTime.now());
});

class WeeklyReviewRepository {
  final AsyncValue<Database> _dbAsync;

  WeeklyReviewRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertReview(WeeklyReview review) async {
    final db = await _db;
    return db.insert('weekly_reviews', review.toMap());
  }

  Future<int> updateReview(WeeklyReview review) async {
    final db = await _db;
    return db.update(
      'weekly_reviews',
      review.toMap(),
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  Future<int> deleteReview(int id) async {
    final db = await _db;
    return db.delete('weekly_reviews', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WeeklyReview>> getAllReviews() async {
    final db = await _db;
    final maps = await db.query('weekly_reviews', orderBy: 'week_start_date DESC');
    return maps.map((m) => WeeklyReview.fromMap(m)).toList();
  }

  Future<WeeklyReview?> getReviewForWeek(String weekStartDate) async {
    final db = await _db;
    final maps = await db.query(
      'weekly_reviews',
      where: 'week_start_date = ?',
      whereArgs: [weekStartDate],
    );
    if (maps.isEmpty) return null;
    return WeeklyReview.fromMap(maps.first);
  }

  Future<WeekStats> getWeekStats(DateTime date) async {
    final db = await _db;
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final recordCount = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records 
      WHERE occurred_at >= ? AND occurred_at < ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final totalMinutes = await db.rawQuery('''
      SELECT COALESCE(SUM(duration_sec), 0) as total FROM episode_records 
      WHERE occurred_at >= ? AND occurred_at < ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final completedGoals = await db.rawQuery('''
      SELECT COUNT(*) as count FROM goals 
      WHERE status = 'completed' 
      AND updated_at >= ? AND updated_at < ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final completedHabits = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_logs 
      WHERE completed_at >= ? AND completed_at < ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final moodData = await db.rawQuery('''
      SELECT AVG(mood_level) as avg FROM mood_entries 
      WHERE created_at >= ? AND created_at < ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final topActivities = await db.rawQuery('''
      SELECT tn.name, COUNT(*) as count 
      FROM episode_records er
      JOIN thing_names tn ON er.thing_name_id = tn.id
      WHERE er.occurred_at >= ? AND er.occurred_at < ?
      GROUP BY tn.name
      ORDER BY count DESC
      LIMIT 5
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final activities = <String, int>{};
    for (final row in topActivities) {
      activities[row['name'] as String] = row['count'] as int;
    }

    return WeekStats(
      recordCount: recordCount.first['count'] as int? ?? 0,
      totalMinutes: ((totalMinutes.first['total'] as int? ?? 0) / 60).round(),
      completedGoals: completedGoals.first['count'] as int? ?? 0,
      completedHabits: completedHabits.first['count'] as int? ?? 0,
      topActivities: activities,
      moodAverage: moodData.first['avg'] as double? ?? 0,
    );
  }

  String getWeekStartDate(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  String getWeekEndDate(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';
  }
}

class WeeklyReviewsNotifier extends StateNotifier<AsyncValue<List<WeeklyReview>>> {
  final WeeklyReviewRepository _repository;

  WeeklyReviewsNotifier(this._repository) : super(const AsyncValue.loading()) {
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

  Future<void> addReview(WeeklyReview review) async {
    try {
      await _repository.insertReview(review);
      await loadReviews();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateReview(WeeklyReview review) async {
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