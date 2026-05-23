import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/annual_review/domain/annual_review_models.dart';

/// 年度回顾服务 Provider
final annualReviewServiceProvider = Provider<AnnualReviewService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return AnnualReviewService(dbAsync);
});

/// 年度统计数据 Provider
final annualStatisticsProvider = FutureProvider.family<AnnualStatistics, int>((ref, year) async {
  final service = ref.watch(annualReviewServiceProvider);
  return service.getAnnualStatistics(year);
});

/// 年度回顾 Provider
final annualReviewProvider = FutureProvider.family<AnnualReview?, int>((ref, year) async {
  final service = ref.watch(annualReviewServiceProvider);
  return service.getAnnualReview(year);
});

/// 年度目标列表 Provider
final yearlyGoalsProvider = FutureProvider.family<List<YearlyGoal>, int>((ref, year) async {
  final service = ref.watch(annualReviewServiceProvider);
  return service.getYearlyGoals(year);
});

class AnnualReviewService {
  final AsyncValue<Database> _dbAsync;

  AnnualReviewService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取年度统计数据
  Future<AnnualStatistics> getAnnualStatistics(int year) async {
    final db = await _db;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

    // 获取记录统计
    final records = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_records,
        COALESCE(SUM(duration_sec), 0) / 60 as total_minutes,
        COUNT(DISTINCT DATE(occurred_at)) as active_days
      FROM episode_records
      WHERE occurred_at BETWEEN ? AND ?
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    final totalRecords = records.first['total_records'] as int? ?? 0;
    final totalMinutes = records.first['total_minutes'] as int? ?? 0;
    final activeDays = records.first['active_days'] as int? ?? 0;

    // 获取习惯完成率
    final habits = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed
      FROM habits
      WHERE created_at BETWEEN ? AND ?
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    final habitTotal = habits.first['total'] as int? ?? 0;
    final habitCompleted = habits.first['completed'] as int? ?? 0;
    final habitCompletionRate = habitTotal > 0 ? (habitCompleted / habitTotal * 100) : 0.0;

    // 获取平均情绪
    final moods = await db.rawQuery('''
      SELECT AVG(mood_level) as avg_mood
      FROM mood_journals
      WHERE date BETWEEN ? AND ?
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    final avgMoodScore = (moods.first['avg_mood'] as num?)?.toDouble() ?? 3.0;

    // 获取最长连续天数
    final streakDays = await _calculateLongestStreak(year);

    // 获取目标完成情况
    final goals = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
      FROM goals
      WHERE created_at BETWEEN ? AND ?
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    final goalsTotal = goals.first['total'] as int? ?? 0;
    final goalsCompleted = goals.first['completed'] as int? ?? 0;

    // 获取 Top 活动
    final topActivities = await _getTopActivities(year);

    // 获取月度数据
    final monthlyData = await _getMonthlyData(year);

    return AnnualStatistics(
      totalRecords: totalRecords,
      totalMinutes: totalMinutes,
      activeDays: activeDays,
      habitCompletionRate: habitCompletionRate,
      avgMoodScore: avgMoodScore,
      streakDays: streakDays,
      goalsCompleted: goalsCompleted,
      goalsTotal: goalsTotal,
      topActivities: topActivities,
      monthlyData: monthlyData,
    );
  }

  Future<int> _calculateLongestStreak(int year) async {
    final db = await _db;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);

    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(occurred_at) as record_date
      FROM episode_records
      WHERE occurred_at BETWEEN ? AND ?
      ORDER BY record_date
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    if (result.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;
    DateTime? previousDate;

    for (final row in result) {
      final date = DateTime.parse(row['record_date'] as String);
      if (previousDate != null) {
        final diff = date.difference(previousDate).inDays;
        if (diff == 1) {
          currentStreak++;
          longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
        } else {
          currentStreak = 1;
        }
      }
      previousDate = date;
    }

    return longestStreak;
  }

  Future<List<TopActivity>> _getTopActivities(int year) async {
    final db = await _db;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT 
        tn.name,
        SUM(r.duration_sec) / 60 as total_minutes,
        COUNT(*) as count
      FROM episode_records r
      INNER JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE r.occurred_at BETWEEN ? AND ?
      GROUP BY tn.name
      ORDER BY total_minutes DESC
      LIMIT 10
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    return result.map((row) => TopActivity(
      name: row['name'] as String,
      minutes: row['total_minutes'] as int? ?? 0,
      count: row['count'] as int? ?? 0,
    )).toList();
  }

  Future<List<MonthlyData>> _getMonthlyData(int year) async {
    final db = await _db;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT 
        strftime('%m', occurred_at) as month,
        COUNT(*) as record_count,
        COALESCE(SUM(duration_sec), 0) / 60 as minutes
      FROM episode_records
      WHERE occurred_at BETWEEN ? AND ?
      GROUP BY strftime('%m', occurred_at)
      ORDER BY month
    ''', [startOfYear.toIso8601String(), endOfYear.toIso8601String()]);

    return result.map((row) => MonthlyData(
      month: int.parse(row['month'] as String),
      recordCount: row['record_count'] as int? ?? 0,
      minutes: row['minutes'] as int? ?? 0,
    )).toList();
  }

  /// 获取年度回顾
  Future<AnnualReview?> getAnnualReview(int year) async {
    final db = await _db;
    final maps = await db.query(
      'annual_reviews',
      where: 'year = ?',
      whereArgs: [year],
    );

    if (maps.isEmpty) return null;
    return AnnualReview.fromMap(maps.first);
  }

  /// 保存年度回顾
  Future<int> saveAnnualReview(AnnualReview review) async {
    final db = await _db;

    final existing = await db.query(
      'annual_reviews',
      where: 'year = ?',
      whereArgs: [review.year],
    );

    if (existing.isNotEmpty) {
      return db.update(
        'annual_reviews',
        review.toMap()..remove('id'),
        where: 'year = ?',
        whereArgs: [review.year],
      );
    } else {
      return db.insert('annual_reviews', review.toMap()..remove('id'));
    }
  }

  /// 获取年度目标
  Future<List<YearlyGoal>> getYearlyGoals(int year) async {
    final db = await _db;
    final maps = await db.query(
      'yearly_goals',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => YearlyGoal.fromMap(m)).toList();
  }

  /// 添加年度目标
  Future<int> addYearlyGoal(YearlyGoal goal) async {
    final db = await _db;
    return db.insert('yearly_goals', goal.toMap()..remove('id'));
  }

  /// 更新年度目标
  Future<int> updateYearlyGoal(YearlyGoal goal) async {
    final db = await _db;
    return db.update(
      'yearly_goals',
      goal.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  /// 删除年度目标
  Future<int> deleteYearlyGoal(int id) async {
    final db = await _db;
    return db.delete('yearly_goals', where: 'id = ?', whereArgs: [id]);
  }

  /// 生成年度回顾报告
  Future<AnnualReview> generateAnnualReview(int year) async {
    final stats = await getAnnualStatistics(year);

    final review = AnnualReview(
      year: year,
      totalRecords: stats.totalRecords,
      totalMinutes: stats.totalMinutes,
      topActivities: stats.topActivities.map((a) => a.name).toList(),
      habitCompletionRate: stats.habitCompletionRate,
      avgMoodScore: stats.avgMoodScore,
    );

    await saveAnnualReview(review);
    return review;
  }
}