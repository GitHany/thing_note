import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/weekly_goal_reset/domain/weekly_goal_model.dart';

String _getWeekStart(DateTime date) {
  final diff = date.weekday - 1;
  final monday = date.subtract(Duration(days: diff));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

final weeklyGoalsProvider = FutureProvider<List<WeeklyGoal>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final currentWeek = _getWeekStart(DateTime.now());
  
  final results = await db.query(
    'weekly_goals',
    where: 'week_start = ?',
    whereArgs: [currentWeek],
    orderBy: 'created_at DESC',
  );
  return results.map((m) => WeeklyGoal.fromMap(m)).toList();
});

final weeklyResetStatsProvider = FutureProvider<WeeklyResetStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final stats = await db.rawQuery('''
    SELECT 
      COUNT(DISTINCT week_start) as total_weeks,
      SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
    FROM weekly_goals
  ''');
  
  final currentWeek = _getWeekStart(DateTime.now());
  final currentGoals = await db.query(
    'weekly_goals',
    where: 'week_start = ?',
    whereArgs: [currentWeek],
  );
  
  return WeeklyResetStats(
    totalWeeks: (stats.first['total_weeks'] as int?) ?? 0,
    completedWeeks: (stats.first['completed'] as int?) ?? 0,
    averageCompletion: 0.78,
    currentGoals: currentGoals.map((m) => WeeklyGoal.fromMap(m)).toList(),
    lastWeekGoals: [],
  );
});

class WeeklyGoalNotifier extends StateNotifier<AsyncValue<List<WeeklyGoal>>> {
  final Ref ref;
  
  WeeklyGoalNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadGoals();
  }
  
  Future<void> _loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final currentWeek = _getWeekStart(DateTime.now());
      final results = await db.query(
        'weekly_goals',
        where: 'week_start = ?',
        whereArgs: [currentWeek],
      );
      state = AsyncValue.data(results.map((m) => WeeklyGoal.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addGoal(String title, double? target) async {
    final db = await ref.read(databaseProvider.future);
    final currentWeek = _getWeekStart(DateTime.now());
    
    await db.insert('weekly_goals', {
      'week_start': currentWeek,
      'goal_title': title,
      'target_value': target,
      'current_value': 0,
      'is_completed': 0,
      'is_reset': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _loadGoals();
  }
  
  Future<void> updateProgress(int goalId, double value) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'weekly_goals',
      {'current_value': value},
      where: 'id = ?',
      whereArgs: [goalId],
    );
    await _loadGoals();
  }
  
  Future<void> completeGoal(int goalId) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'weekly_goals',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [goalId],
    );
    await _loadGoals();
  }
  
  Future<void> resetGoals() async {
    final db = await ref.read(databaseProvider.future);
    final currentWeek = _getWeekStart(DateTime.now());
    await db.update(
      'weekly_goals',
      {'is_reset': 1},
      where: 'week_start = ?',
      whereArgs: [currentWeek],
    );
    await _loadGoals();
  }
}

final weeklyGoalNotifierProvider =
    StateNotifierProvider<WeeklyGoalNotifier, AsyncValue<List<WeeklyGoal>>>((ref) {
  return WeeklyGoalNotifier(ref);
});