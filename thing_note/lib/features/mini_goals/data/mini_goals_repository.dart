import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final miniGoalsRepositoryProvider = Provider<MiniGoalsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MiniGoalsRepository(dbAsync);
});

class MiniGoalsRepository {
  final AsyncValue<Database> _dbAsync;

  MiniGoalsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<Map<String, dynamic>>> getPendingGoals() async {
    final db = await _db;
    return db.query(
      'micro_goals',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'priority DESC, created_at ASC',
    );
  }

  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final db = await _db;
    return db.insert('micro_goals', goal);
  }

  Future<void> completeGoal(int goalId) async {
    final db = await _db;
    await db.update(
      'micro_goals',
      {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await _db;
    final pending = await db.query('micro_goals', where: 'status = ?', whereArgs: ['pending']);
    final completed = await db.query('micro_goals', where: 'status = ?', whereArgs: ['completed']);
    return {'pending': pending.length, 'completed': completed.length};
  }
}
