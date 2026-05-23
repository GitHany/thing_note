import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_weekly_planner/domain/weekly_plan.dart';

class WeeklyPlannerRepository {
  final Ref _ref;

  WeeklyPlannerRepository(this._ref);

  Future<List<WeeklyPlan>> getAllPlans() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'weekly_plans',
      orderBy: 'day_of_week ASC, time_slot ASC',
    );
    return result.map((e) => WeeklyPlan.fromMap(e)).toList();
  }

  Future<List<WeeklyPlan>> getPlansByDay(int dayOfWeek) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'weekly_plans',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
      orderBy: 'time_slot ASC',
    );
    return result.map((e) => WeeklyPlan.fromMap(e)).toList();
  }

  Future<List<WeeklyPlan>> getTodayPlans() async {
    final dayOfWeek = DateTime.now().weekday;
    return getPlansByDay(dayOfWeek);
  }

  Future<int> insertPlan(WeeklyPlan plan) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('weekly_plans', plan.toMap()..remove('id'));
  }

  Future<int> updatePlan(WeeklyPlan plan) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'weekly_plans',
      plan.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deletePlan(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('weekly_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleComplete(int id, bool isCompleted) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'weekly_plans',
      {
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getWeekCompletionStats() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.rawQuery('''
      SELECT day_of_week, 
             COUNT(*) as total,
             SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
      FROM weekly_plans
      GROUP BY day_of_week
    ''');
    
    final stats = <String, int>{};
    for (final row in result) {
      final day = row['day_of_week'] as int;
      final total = row['total'] as int;
      final completed = row['completed'] as int;
      stats['day_$day'] = total;
      stats['completed_$day'] = completed;
    }
    return stats;
  }
}