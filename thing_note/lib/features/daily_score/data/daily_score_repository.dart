import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/daily_score/domain/daily_score.dart';

final dailyScoreRepositoryProvider = Provider<DailyScoreRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyScoreRepository(dbAsync);
});

class DailyScoreRepository {
  final AsyncValue<Database> _dbAsync;

  DailyScoreRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertOrUpdate(DailyScore score) async {
    final db = await _db;
    final existing = await db.query(
      'daily_scores',
      where: 'date = ?',
      whereArgs: [score.date],
    );

    if (existing.isEmpty) {
      return await db.insert('daily_scores', score.toMap());
    } else {
      return await db.update(
        'daily_scores',
        score.toMap(),
        where: 'date = ?',
        whereArgs: [score.date],
      );
    }
  }

  Future<DailyScore?> getByDate(String date) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_scores',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return DailyScore.fromMap(maps.first);
  }

  Future<List<DailyScore>> getRecent(int days) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_scores',
      orderBy: 'date DESC',
      limit: days,
    );
    return maps.map((map) => DailyScore.fromMap(map)).toList();
  }

  Future<void> calculateAndSaveTodayScore() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Calculate productivity score from records
    final recordCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM episode_records WHERE date(occurred_at) = ?',
      [today],
    );

    final completedGoals = await db.rawQuery(
      'SELECT COUNT(*) as count FROM goals WHERE status = \'completed\' AND date(updated_at) = ?',
      [today],
    );

    final completedHabits = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ritual_completions WHERE date(completed_at) = ?',
      [today],
    );

    // Calculate health score
    final waterIntake = await db.rawQuery('''
      SELECT SUM(total_ml) as total FROM water_intake_records 
      WHERE date = ?
    ''', [today]);

    final sleepRecord = await db.rawQuery(
      'SELECT duration_minutes FROM sleep_records WHERE date = ? LIMIT 1',
      [today],
    );

    // Calculate mood score
    final moodEntry = await db.rawQuery(
      'SELECT mood FROM mood_entries WHERE date(timestamp) = ? LIMIT 1',
      [today],
    );

    // Calculate social score
    final socialInteractions = await db.rawQuery(
      'SELECT COUNT(*) as count FROM social_interactions WHERE date(interaction_date) = ?',
      [today],
    );

    // Calculate scores
    double productivityScore = 0;
    if (recordCount.first['count'] != null) {
      final records = recordCount.first['count'] as int;
      productivityScore = (records * 5).clamp(0, 100).toDouble();
    }

    double healthScore = 0;
    final water = (waterIntake.first['total'] as num?)?.toDouble() ?? 0;
    final sleepMinutes = (sleepRecord.isNotEmpty ? sleepRecord.first['duration_minutes'] as int? : null) ?? 0;
    healthScore = ((water / 2000) * 50 + (sleepMinutes / 480) * 50).clamp(0, 100);

    double moodScore = 0;
    if (moodEntry.isNotEmpty) {
      moodScore = ((moodEntry.first['mood'] as int) / 5 * 100);
    }

    double socialScore = 0;
    int interactions = 0;
    if (socialInteractions.first['count'] != null) {
      interactions = socialInteractions.first['count'] as int;
      socialScore = (interactions * 20).clamp(0, 100).toDouble();
    }

    final overallScore = (productivityScore + healthScore + moodScore + socialScore) / 4;

    // Create achievements
    final achievements = <String>[];
    if ((recordCount.first['count'] as int? ?? 0) >= 5) achievements.add('记录达人');
    if ((completedGoals.first['count'] as int? ?? 0) > 0) achievements.add('目标达成');
    if ((completedHabits.first['count'] as int? ?? 0) >= 3) achievements.add('习惯达人');
    if (water >= 2000) achievements.add('饮水达标');
    if (sleepMinutes >= 420) achievements.add('睡眠充足');
    if (interactions >= 3) achievements.add('社交活跃');

    final score = DailyScore(
      date: today,
      productivityScore: productivityScore,
      healthScore: healthScore,
      moodScore: moodScore,
      socialScore: socialScore,
      overallScore: overallScore,
      achievements: achievements,
    );

    await insertOrUpdate(score);
  }

  Future<Map<String, double>> getWeeklyAverage() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        AVG(productivity_score) as productivity,
        AVG(health_score) as health,
        AVG(mood_score) as mood,
        AVG(social_score) as social,
        AVG(overall_score) as overall
      FROM daily_scores
      WHERE date >= datetime('now', '-7 days')
    ''');

    final row = result.first;
    return {
      'productivity': (row['productivity'] as num?)?.toDouble() ?? 0,
      'health': (row['health'] as num?)?.toDouble() ?? 0,
      'mood': (row['mood'] as num?)?.toDouble() ?? 0,
      'social': (row['social'] as num?)?.toDouble() ?? 0,
      'overall': (row['overall'] as num?)?.toDouble() ?? 0,
    };
  }
}