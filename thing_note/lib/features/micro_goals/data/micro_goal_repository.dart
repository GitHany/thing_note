import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/micro_goal_models.dart';

final microGoalRepositoryProvider = Provider<MicroGoalRepository>((ref) {
  return MicroGoalRepository(ref.watch(databaseProvider).value!);
});

class MicroGoalRepository {
  final Database _db;

  MicroGoalRepository(this._db);

  Future<int> insert(MicroGoal goal) async {
    return await _db.insert('micro_goals', goal.toMap());
  }

  Future<int> update(MicroGoal goal) async {
    return await _db.update(
      'micro_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete('micro_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MicroGoal>> getPending() async {
    final maps = await _db.query(
      'micro_goals',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'priority DESC, created_at ASC',
    );
    return maps.map((m) => MicroGoal.fromMap(m)).toList();
  }

  Future<List<MicroGoal>> getCompleted() async {
    final maps = await _db.query(
      'micro_goals',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'completed_at DESC',
    );
    return maps.map((m) => MicroGoal.fromMap(m)).toList();
  }

  Future<void> complete(int id, int actualMinutes) async {
    await _db.update(
      'micro_goals',
      {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'actual_minutes': actualMinutes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
        AVG(actual_minutes) as avg_time,
        SUM(CASE WHEN status = 'completed' THEN estimated_minutes ELSE 0 END) as total_estimated,
        SUM(actual_minutes) as total_actual
      FROM micro_goals
    ''');
    return result.first;
  }
}