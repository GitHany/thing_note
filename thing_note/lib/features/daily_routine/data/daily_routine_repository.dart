import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/daily_routine/domain/daily_routine.dart';

final dailyRoutineRepositoryProvider = Provider<DailyRoutineRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyRoutineRepository(dbAsync);
});

class DailyRoutineRepository {
  final AsyncValue<Database> _dbAsync;

  DailyRoutineRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertRoutine(DailyRoutine routine) async {
    final db = await _db;
    return await db.insert('daily_routines', routine.toMap());
  }

  Future<List<DailyRoutine>> getAllRoutines() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_routines',
      orderBy: 'time_slot ASC',
    );
    return maps.map((map) => DailyRoutine.fromMap(map)).toList();
  }

  Future<List<DailyRoutine>> getActiveRoutines() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_routines',
      where: 'is_active = 1',
      orderBy: 'time_slot ASC',
    );
    return maps.map((map) => DailyRoutine.fromMap(map)).toList();
  }

  Future<int> updateRoutine(DailyRoutine routine) async {
    final db = await _db;
    return await db.update(
      'daily_routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  Future<int> deleteRoutine(int id) async {
    final db = await _db;
    return await db.delete(
      'daily_routines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> completeRoutine(int routineId, String date) async {
    final db = await _db;
    final completion = RoutineCompletion(
      routineId: routineId,
      completedDate: date,
      completedAt: DateTime.now(),
    );
    return await db.insert('routine_completions', completion.toMap());
  }

  Future<List<RoutineCompletion>> getCompletions(String date) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'routine_completions',
      where: 'completed_date = ?',
      whereArgs: [date],
    );
    return maps.map((map) => RoutineCompletion.fromMap(map)).toList();
  }

  Future<bool> isCompletedToday(int routineId) async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.query(
      'routine_completions',
      where: 'routine_id = ? AND completed_date = ?',
      whereArgs: [routineId, today],
    );
    return result.isNotEmpty;
  }

  Future<int> getTodayCompletionRate() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final totalRoutines = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_routines WHERE is_active = 1',
    );
    
    final completed = await db.rawQuery(
      'SELECT COUNT(DISTINCT routine_id) as count FROM routine_completions WHERE completed_date = ?',
      [today],
    );

    final total = totalRoutines.first['count'] as int? ?? 0;
    final done = completed.first['count'] as int? ?? 0;
    
    if (total == 0) return 0;
    return ((done / total) * 100).round();
  }
}