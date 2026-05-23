import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_planner/domain/daily_task.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final dailyPlannerRepositoryProvider = Provider<DailyPlannerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyPlannerRepository(dbAsync);
});

final todayTasksProvider = StateNotifierProvider<TodayTasksNotifier, AsyncValue<List<DailyTask>>>((ref) {
  final repository = ref.watch(dailyPlannerRepositoryProvider);
  return TodayTasksNotifier(repository);
});

final taskStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(dailyPlannerRepositoryProvider);
  return repository.getTaskStats();
});

class DailyPlannerRepository {
  final AsyncValue<Database> _dbAsync;

  DailyPlannerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertTask(DailyTask task) async {
    final db = await _db;
    return db.insert('daily_tasks', task.toMap());
  }

  Future<int> updateTask(DailyTask task) async {
    final db = await _db;
    return db.update(
      'daily_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await _db;
    return db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DailyTask>> getTasksByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'daily_tasks',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'is_completed ASC, priority DESC, created_at DESC',
    );
    return maps.map((m) => DailyTask.fromMap(m)).toList();
  }

  Future<List<DailyTask>> getTasksForDateRange(String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query(
      'daily_tasks',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, is_completed ASC, priority DESC',
    );
    return maps.map((m) => DailyTask.fromMap(m)).toList();
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    final db = await _db;
    final tasks = await db.query('daily_tasks', where: 'id = ?', whereArgs: [taskId]);
    if (tasks.isEmpty) return;

    final task = DailyTask.fromMap(tasks.first);
    final newCompleted = !task.isCompleted;

    await db.update(
      'daily_tasks',
      {
        'is_completed': newCompleted ? 1 : 0,
        'completed_at': newCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<Map<String, int>> getTaskStats() async {
    final db = await _db;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM daily_tasks WHERE date = ?', [today]);
    final completed = await db.rawQuery('SELECT COUNT(*) as count FROM daily_tasks WHERE date = ? AND is_completed = 1', [today]);
    
    return {
      'total': total.first['count'] as int? ?? 0,
      'completed': completed.first['count'] as int? ?? 0,
    };
  }

  Future<int> getCompletionRate(String startDate, String endDate) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
      FROM daily_tasks 
      WHERE date >= ? AND date <= ?
    ''', [startDate, endDate]);
    
    if (result.isEmpty) return 0;
    final total = result.first['total'] as int? ?? 0;
    final completed = result.first['completed'] as int? ?? 0;
    
    if (total == 0) return 0;
    return ((completed / total) * 100).round();
  }
}

class TodayTasksNotifier extends StateNotifier<AsyncValue<List<DailyTask>>> {
  final DailyPlannerRepository _repository;

  TodayTasksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getTasksByDate(_today);
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(DailyTask task) async {
    try {
      await _repository.insertTask(task);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(DailyTask task) async {
    try {
      await _repository.updateTask(task);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _repository.deleteTask(id);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCompletion(int taskId) async {
    try {
      await _repository.toggleTaskCompletion(taskId);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}