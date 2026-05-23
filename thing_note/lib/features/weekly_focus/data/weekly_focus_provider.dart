// Weekly Focus Provider
// Version: 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/weekly_focus/domain/weekly_focus_models.dart';

// Current week focus provider
final currentWeekFocusProvider = FutureProvider<WeeklyFocusWithGoals?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final weekNumber = _getWeekNumber(now);
  
  final results = await db.query(
    'weekly_focuses',
    where: 'week_number = ? AND year = ?',
    whereArgs: [weekNumber, now.year],
  );
  
  if (results.isEmpty) return null;
  
  final focus = WeeklyFocus.fromMap(results.first);
  final goals = await db.query(
    'weekly_goals',
    where: 'focus_id = ?',
    whereArgs: [focus.id],
    orderBy: 'sort_order ASC',
  );
  
  return WeeklyFocusWithGoals(
    focus: focus,
    goals: goals.map((g) => WeeklyGoal.fromMap(g)).toList(),
  );
});

// All weekly focuses provider
final allWeeklyFocusesProvider = FutureProvider<List<WeeklyFocus>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'weekly_focuses',
    orderBy: 'year DESC, week_number DESC',
  );
  return results.map((r) => WeeklyFocus.fromMap(r)).toList();
});

// Recent focuses (last 4 weeks)
final recentFocusesProvider = FutureProvider<List<WeeklyFocusWithGoals>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  
  final results = await db.query(
    'weekly_focuses',
    where: 'year = ? AND week_number >= ?',
    whereArgs: [now.year, now.year == now.year ? (now.weekday ~/ 7) + 1 : 1],
    orderBy: 'year DESC, week_number DESC',
    limit: 4,
  );
  
  final List<WeeklyFocusWithGoals> focuses = [];
  for (final r in results) {
    final focus = WeeklyFocus.fromMap(r);
    final goals = await db.query(
      'weekly_goals',
      where: 'focus_id = ?',
      whereArgs: [focus.id],
    );
    focuses.add(WeeklyFocusWithGoals(
      focus: focus,
      goals: goals.map((g) => WeeklyGoal.fromMap(g)).toList(),
    ));
  }
  
  return focuses;
});

int _getWeekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysDifference = date.difference(firstDayOfYear).inDays;
  return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
}

class WeeklyFocusRepository {
  final dynamic db;
  
  WeeklyFocusRepository(this.db);
  
  Future<int> createFocus(WeeklyFocus focus) async {
    return await db.insert('weekly_focuses', focus.toMap());
  }
  
  Future<void> updateFocus(WeeklyFocus focus) async {
    await db.update(
      'weekly_focuses',
      {...focus.toMap(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [focus.id],
    );
  }
  
  Future<void> deleteFocus(int id) async {
    await db.delete('weekly_goals', where: 'focus_id = ?', whereArgs: [id]);
    await db.delete('weekly_focuses', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> addGoal(WeeklyGoal goal) async {
    final existingGoals = await db.query(
      'weekly_goals',
      where: 'focus_id = ?',
      whereArgs: [goal.focusId],
    );
    final newGoal = WeeklyGoal(
      focusId: goal.focusId,
      title: goal.title,
      sortOrder: existingGoals.length,
    );
    return await db.insert('weekly_goals', newGoal.toMap());
  }
  
  Future<void> updateGoalProgress(int goalId, int progress) async {
    await db.update(
      'weekly_goals',
      {
        'progress': progress,
        'is_completed': progress >= 100 ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
  
  Future<void> deleteGoal(int id) async {
    await db.delete('weekly_goals', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> toggleGoalComplete(int goalId) async {
    final goal = await db.query('weekly_goals', where: 'id = ?', whereArgs: [goalId]);
    if (goal.isEmpty) return;
    
    final isCompleted = (goal.first['is_completed'] as int? ?? 0) == 1;
    await db.update(
      'weekly_goals',
      {
        'is_completed': isCompleted ? 0 : 1,
        'progress': isCompleted ? 0 : 100,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}