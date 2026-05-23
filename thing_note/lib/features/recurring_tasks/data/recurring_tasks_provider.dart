import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/recurring_tasks/domain/recurring_task.dart';

final recurringTasksProvider = StateNotifierProvider<RecurringTasksNotifier, AsyncValue<List<RecurringTask>>>((ref) {
  return RecurringTasksNotifier(ref);
});

class RecurringTasksNotifier extends StateNotifier<AsyncValue<List<RecurringTask>>> {
  final Ref ref;

  RecurringTasksNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadTasks() async {
    try {
      state = const AsyncValue.loading();
      final db = await _db;
      final maps = await db.query('recurring_tasks', orderBy: 'next_due_at ASC');
      final tasks = maps.map((m) => RecurringTask.fromMap(m)).toList();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> addTask(RecurringTask task) async {
    final db = await _db;
    final id = await db.insert('recurring_tasks', task.toMap()..remove('id'));
    await loadTasks();
    return id;
  }

  Future<void> updateTask(RecurringTask task) async {
    final db = await _db;
    await db.update(
      'recurring_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    final db = await _db;
    await db.delete('recurring_tasks', where: 'id = ?', whereArgs: [id]);
    await loadTasks();
  }

  Future<void> completeTask(RecurringTask task) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final nextDue = _calculateNextDue(task.repeatType, task.repeatInterval, task.customDays);
    
    final updated = task.copyWith(
      completedCount: task.completedCount + 1,
      currentStreak: task.currentStreak + 1,
      bestStreak: task.currentStreak + 1 > task.bestStreak ? task.currentStreak + 1 : task.bestStreak,
      lastCompletedAt: now,
      nextDueAt: nextDue,
      updatedAt: now,
    );

    await db.update(
      'recurring_tasks',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    await loadTasks();
  }

  Future<void> skipTask(RecurringTask task) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final nextDue = _calculateNextDue(task.repeatType, task.repeatInterval, task.customDays);
    
    final updated = task.copyWith(
      skippedCount: task.skippedCount + 1,
      currentStreak: 0,
      nextDueAt: nextDue,
      updatedAt: now,
    );

    await db.update(
      'recurring_tasks',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    await loadTasks();
  }

  String _calculateNextDue(String repeatType, int interval, String? customDays) {
    final now = DateTime.now();
    DateTime next;
    
    switch (repeatType) {
      case 'daily':
        next = now.add(Duration(days: interval));
        break;
      case 'weekly':
        next = now.add(Duration(days: 7 * interval));
        break;
      case 'monthly':
        next = DateTime(now.year, now.month + interval, now.day);
        break;
      case 'yearly':
        next = DateTime(now.year + interval, now.month, now.day);
        break;
      case 'custom':
        next = now.add(Duration(days: interval));
        break;
      default:
        next = now.add(Duration(days: 1));
    }
    
    return next.toIso8601String();
  }

  Future<List<RecurringTask>> getTodayTasks() async {
    final db = await _db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    
    final maps = await db.query(
      'recurring_tasks',
      where: 'next_due_at >= ? AND next_due_at <= ? AND is_active = 1',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'priority DESC, next_due_at ASC',
    );
    
    return maps.map((m) => RecurringTask.fromMap(m)).toList();
  }

  Future<List<RecurringTask>> getOverdueTasks() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      'recurring_tasks',
      where: 'next_due_at < ? AND is_active = 1',
      whereArgs: [now],
      orderBy: 'next_due_at ASC',
    );
    
    return maps.map((m) => RecurringTask.fromMap(m)).toList();
  }
}