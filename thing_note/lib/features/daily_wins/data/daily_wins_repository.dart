import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final dailyWinsRepositoryProvider = Provider<DailyWinsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyWinsRepository(dbAsync);
});

class DailyWinsRepository {
  final AsyncValue<Database> _dbAsync;

  DailyWinsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<Map<String, dynamic>>> getWinsForDate(String date) async {
    final db = await _db;
    return db.query(
      'daily_wins',
      where: 'win_date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> insertWin(Map<String, dynamic> win) async {
    final db = await _db;
    return db.insert('daily_wins', win);
  }

  Future<int> deleteWin(int id) async {
    final db = await _db;
    return db.delete('daily_wins', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getWeeklyStats(String weekStart) async {
    final db = await _db;
    final wins = await db.query(
      'daily_wins',
      where: 'win_date >= ?',
      whereArgs: [weekStart],
    );

    int totalPoints = 0;
    for (final win in wins) {
      totalPoints += win['points'] as int? ?? 10;
    }

    return {'totalWins': wins.length, 'totalPoints': totalPoints};
  }
}