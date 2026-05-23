import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final dailyProgressRepositoryProvider = Provider<DailyProgressRepository>((ref) {
  return DailyProgressRepository(ref.watch(databaseProvider.future));
});

class DailyProgressRepository {
  final Future<Database> _dbFuture;

  DailyProgressRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<Map<String, dynamic>> getTodaySnapshot() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final results = await db.query(
      'daily_progress_snapshots',
      where: 'snapshot_date = ?',
      whereArgs: [today],
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    final recordCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM episode_records WHERE DATE(occurred_at) = ?", [today])
    ) ?? 0;

    final habitCompletion = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM habit_check_ins WHERE check_date = ?', [today])
    ) ?? 0;

    return {
      'snapshot_date': today,
      'completed_items': recordCount,
      'total_items': 10,
      'progress_percent': (recordCount / 10 * 100).toInt(),
      'habit_completion': habitCompletion,
      'goal_progress': 60,
      'highlights': ['完成了重要工作', '坚持运动'],
    };
  }

  Future<void> saveSnapshot(Map<String, dynamic> snapshot) async {
    final db = await _db;
    await db.insert(
      'daily_progress_snapshots',
      snapshot,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}