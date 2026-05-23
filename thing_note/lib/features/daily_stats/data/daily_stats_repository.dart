import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_stats/domain/daily_stats_snapshot.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final dailyStatsRepositoryProvider = Provider<DailyStatsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyStatsRepository(dbAsync);
});

final dailyStatsTodayProvider = FutureProvider<DailyStatsSnapshot?>((ref) async {
  final repo = ref.watch(dailyStatsRepositoryProvider);
  return repo.getStatsByDate(_todayDate());
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class DailyStatsRepository {
  final AsyncValue<Database> _dbAsync;

  DailyStatsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertStats(DailyStatsSnapshot stats) async {
    final db = await _db;
    return db.insert('daily_stats_snapshot', stats.toMap());
  }

  Future<int> updateStats(DailyStatsSnapshot stats) async {
    final db = await _db;
    return db.update('daily_stats_snapshot', stats.toMap(), where: 'id = ?', whereArgs: [stats.id]);
  }

  Future<int> upsertStats(DailyStatsSnapshot stats) async {
    final db = await _db;
    final existing = await db.query('daily_stats_snapshot', where: 'date = ?', whereArgs: [stats.date]);
    if (existing.isNotEmpty) {
      return db.update('daily_stats_snapshot', stats.toMap(), where: 'id = ?', whereArgs: [existing.first['id']]);
    }
    return db.insert('daily_stats_snapshot', stats.toMap());
  }

  Future<DailyStatsSnapshot?> getStatsByDate(String date) async {
    final db = await _db;
    final maps = await db.query('daily_stats_snapshot', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return DailyStatsSnapshot.fromMap(maps.first);
  }

  Future<List<DailyStatsSnapshot>> getStatsForMonth(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    final maps = await db.query(
      'daily_stats_snapshot',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DailyStatsSnapshot.fromMap(m)).toList();
  }

  Future<List<DailyStatsSnapshot>> getStatsForWeek(String endDate) async {
    final db = await _db;
    final end = DateTime.parse(endDate);
    final start = end.subtract(const Duration(days: 6));
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'daily_stats_snapshot',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DailyStatsSnapshot.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getWeeklySummary(String date) async {
    final stats = await getStatsForWeek(date);
    if (stats.isEmpty) return {'avg_records': 0.0, 'total_minutes': 0, 'avg_habits': 0.0};
    final double avgRecords = stats.fold(0.0, (sum, s) => sum + s.recordsCount) / stats.length;
    final int totalMinutes = stats.fold(0, (sum, s) => sum + s.totalDurationMinutes);
    final double avgHabits = stats.fold(0.0, (sum, s) => sum + s.habitsCompleted) / stats.length;
    return {
      'avg_records': avgRecords,
      'total_minutes': totalMinutes,
      'avg_habits': avgHabits,
      'days_recorded': stats.length,
    };
  }
}
