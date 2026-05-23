import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/quick_stats/domain/quick_stat.dart';

final quickStatsRepositoryProvider = Provider<QuickStatsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickStatsRepository(dbAsync);
});

class QuickStatsRepository {
  final AsyncValue<Database> _dbAsync;

  QuickStatsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertOrUpdate(QuickStat stat) async {
    final db = await _db;
    final existing = await db.query(
      'quick_stats',
      where: 'date = ?',
      whereArgs: [stat.date],
    );

    if (existing.isEmpty) {
      return await db.insert('quick_stats', stat.toMap());
    } else {
      return await db.update(
        'quick_stats',
        stat.toMap(),
        where: 'date = ?',
        whereArgs: [stat.date],
      );
    }
  }

  Future<QuickStat?> getByDate(String date) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_stats',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return QuickStat.fromMap(maps.first);
  }

  Future<List<QuickStat>> getRecentStats(int days) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_stats',
      orderBy: 'date DESC',
      limit: days,
    );
    return maps.map((map) => QuickStat.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getOverview() async {
    final db = await _db;

    final totalRecords = await db.rawQuery(
      'SELECT COUNT(*) as count FROM episode_records',
    );

    final totalDuration = await db.rawQuery(
      'SELECT SUM(duration_sec) as total FROM episode_records WHERE duration_sec > 0',
    );

    final todayRecords = await db.rawQuery(
      "SELECT COUNT(*) as count FROM episode_records WHERE date(occurred_at) = date('now')",
    );

    final thisWeekRecords = await db.rawQuery(
      "SELECT COUNT(*) as count FROM episode_records WHERE occurred_at >= datetime('now', '-7 days')",
    );

    return {
      'totalRecords': totalRecords.first['count'] ?? 0,
      'totalDuration': (totalDuration.first['total'] ?? 0) as int,
      'todayRecords': todayRecords.first['count'] ?? 0,
      'thisWeekRecords': thisWeekRecords.first['count'] ?? 0,
    };
  }
}
