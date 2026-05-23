import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_habit_scheduling/domain/habit_schedule_model.dart';

final habitSchedulesProvider = FutureProvider<List<HabitSchedule>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('smart_habit_schedules', orderBy: 'priority DESC');
  return results.map((m) => HabitSchedule.fromMap(m)).toList();
});

final scheduleStatsProvider = FutureProvider<HabitSchedulingStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final countResult = await db.rawQuery('''
    SELECT 
      COUNT(*) as total,
      SUM(is_enabled) as active,
      AVG(CASE WHEN success_count > 0 THEN CAST(success_count AS REAL) / NULLIF(last_executed, 0) ELSE 0 END) as avg_success
    FROM smart_habit_schedules
  ''');
  
  final optimalCount = await db.rawQuery('''
    SELECT COUNT(*) as count FROM smart_habit_schedules 
    WHERE is_enabled = 1 AND success_count >= 5
  ''');
  
  return HabitSchedulingStats(
    totalSchedules: countResult.first['total'] as int? ?? 0,
    activeSchedules: countResult.first['active'] as int? ?? 0,
    averageSuccessRate: (countResult.first['avg_success'] as num?)?.toDouble() ?? 0.0,
    optimalTimeCount: optimalCount.first['count'] as int? ?? 0,
    recommendations: [],
  );
});

class HabitScheduleNotifier extends StateNotifier<AsyncValue<List<HabitSchedule>>> {
  final Ref ref;
  
  HabitScheduleNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSchedules();
  }
  
  Future<void> _loadSchedules() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('smart_habit_schedules', orderBy: 'priority DESC');
      state = AsyncValue.data(results.map((m) => HabitSchedule.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addSchedule(HabitSchedule schedule) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('smart_habit_schedules', schedule.toMap()..remove('id'));
    await _loadSchedules();
  }
  
  Future<void> updateSchedule(HabitSchedule schedule) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'smart_habit_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
    await _loadSchedules();
  }
  
  Future<void> deleteSchedule(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('smart_habit_schedules', where: 'id = ?', whereArgs: [id]);
    await _loadSchedules();
  }
  
  Future<void> markExecuted(int scheduleId) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'smart_habit_schedules',
      {
        'last_executed': DateTime.now().toIso8601String(),
        'success_count': db.rawQuery('SELECT success_count FROM smart_habit_schedules WHERE id = ?', [scheduleId]).then((r) => (r.first['success_count'] as int? ?? 0) + 1),
      },
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
    await _loadSchedules();
  }
}

final habitScheduleNotifierProvider =
    StateNotifierProvider<HabitScheduleNotifier, AsyncValue<List<HabitSchedule>>>((ref) {
  return HabitScheduleNotifier(ref);
});