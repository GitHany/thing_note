import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final weeklyPlannerRepositoryProvider = Provider<WeeklyPlannerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return WeeklyPlannerRepository(dbAsync);
});

class WeeklyPlannerRepository {
  final AsyncValue<Database> _dbAsync;

  WeeklyPlannerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<Map<int, List<Map<String, dynamic>>>> getItemsGroupedByDay() async {
    final db = await _db;
    final items = await db.query('weekly_planner_items', orderBy: 'start_time ASC');

    final Map<int, List<Map<String, dynamic>>> result = {};
    for (int i = 1; i <= 7; i++) {
      result[i] = items.where((item) => item['day_of_week'] == i).toList();
    }
    return result;
  }

  Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await _db;
    return db.insert('weekly_planner_items', item);
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    final db = await _db;
    await db.update('weekly_planner_items', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await _db;
    return db.delete('weekly_planner_items', where: 'id = ?', whereArgs: [id]);
  }
}
