import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/priority_matrix/domain/matrix_task.dart';

final priorityMatrixRepositoryProvider = Provider<PriorityMatrixRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PriorityMatrixRepository(dbAsync);
});

final matrixTasksProvider = StateNotifierProvider<MatrixTasksNotifier, AsyncValue<List<MatrixTask>>>((ref) {
  final repository = ref.watch(priorityMatrixRepositoryProvider);
  return MatrixTasksNotifier(repository);
});

final quadrantTasksProvider = FutureProvider.family<List<MatrixTask>, String>((ref, quadrant) async {
  final repository = ref.watch(priorityMatrixRepositoryProvider);
  return repository.getTasksByQuadrant(quadrant);
});

class PriorityMatrixRepository {
  final AsyncValue<Database> _dbAsync;

  PriorityMatrixRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertTask(MatrixTask task) async {
    final db = await _db;
    return db.insert('priority_matrix_tasks', task.toMap());
  }

  Future<int> updateTask(MatrixTask task) async {
    final db = await _db;
    return db.update('priority_matrix_tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await _db;
    return db.delete('priority_matrix_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MatrixTask>> getAllTasks() async {
    final db = await _db;
    final maps = await db.query('priority_matrix_tasks', orderBy: 'created_at DESC');
    return maps.map((m) => MatrixTask.fromMap(m)).toList();
  }

  Future<List<MatrixTask>> getTasksByQuadrant(String quadrant) async {
    final db = await _db;
    final maps = await db.query(
      'priority_matrix_tasks',
      where: 'quadrant = ?',
      whereArgs: [quadrant],
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return maps.map((m) => MatrixTask.fromMap(m)).toList();
  }

  Future<List<MatrixTask>> getPendingTasks() async {
    final db = await _db;
    final maps = await db.query(
      'priority_matrix_tasks',
      where: 'is_completed = 0',
      orderBy: 'quadrant ASC, created_at DESC',
    );
    return maps.map((m) => MatrixTask.fromMap(m)).toList();
  }

  Future<List<MatrixTask>> getCompletedTasks() async {
    final db = await _db;
    final maps = await db.query(
      'priority_matrix_tasks',
      where: 'is_completed = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => MatrixTask.fromMap(m)).toList();
  }

  Future<void> toggleComplete(int taskId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE priority_matrix_tasks SET is_completed = 1 - is_completed, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), taskId],
    );
  }

  Future<void> moveToQuadrant(int taskId, String newQuadrant) async {
    final db = await _db;
    await db.update(
      'priority_matrix_tasks',
      {'quadrant': newQuadrant, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final stats = <String, dynamic>{};
    
    for (final quadrant in MatrixTask.quadrants) {
      final total = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM priority_matrix_tasks WHERE quadrant = ?',
          [quadrant],
        ),
      ) ?? 0;
      
      final completed = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM priority_matrix_tasks WHERE quadrant = ? AND is_completed = 1',
          [quadrant],
        ),
      ) ?? 0;
      
      stats[quadrant] = {'total': total, 'completed': completed};
    }
    
    return stats;
  }

  Future<double> calculateDragRisk(int taskId) async {
    final db = await _db;
    final maps = await db.query('priority_matrix_tasks', where: 'id = ?', whereArgs: [taskId]);
    if (maps.isEmpty) return 0;
    
    final task = MatrixTask.fromMap(maps.first);
    
    if (task.quadrant == 'not_urgent_not_important') {
      return 0.9;
    } else if (task.quadrant == 'urgent_not_important') {
      return 0.7;
    } else if (task.quadrant == 'not_urgent_important') {
      final daysSinceCreation = DateTime.now().difference(task.createdAt).inDays;
      return (daysSinceCreation / 30).clamp(0.0, 0.8);
    } else if (task.quadrant == 'urgent_important') {
      final daysSinceCreation = DateTime.now().difference(task.createdAt).inDays;
      return (daysSinceCreation / 7).clamp(0.0, 0.5);
    }
    
    return 0;
  }
}

class MatrixTasksNotifier extends StateNotifier<AsyncValue<List<MatrixTask>>> {
  final PriorityMatrixRepository _repository;

  MatrixTasksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getPendingTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(MatrixTask task) async {
    try {
      await _repository.insertTask(task);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleComplete(int taskId) async {
    try {
      await _repository.toggleComplete(taskId);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> moveToQuadrant(int taskId, String newQuadrant) async {
    try {
      await _repository.moveToQuadrant(taskId, newQuadrant);
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
}