// Mini Tasks Provider
// Version: 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mini_tasks/domain/mini_task_models.dart';

// Today's tasks provider
final todayTasksProvider = FutureProvider<List<MiniTask>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'mini_tasks',
    where: 'due_date = ? OR due_date IS NULL',
    whereArgs: [today],
    orderBy: 'priority DESC, sort_order ASC',
  );
  
  return results.map((r) => MiniTask.fromMap(r)).toList();
});

// All pending tasks provider
final allPendingTasksProvider = FutureProvider<List<MiniTask>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final results = await db.query(
    'mini_tasks',
    where: 'is_completed = ? AND status != ?',
    whereArgs: [0, 'cancelled'],
    orderBy: 'due_date ASC, priority DESC',
  );
  
  return results.map((r) => MiniTask.fromMap(r)).toList();
});

// Task groups provider
final taskGroupsProvider = FutureProvider<List<TaskGroup>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('task_groups', orderBy: 'created_at DESC');
  return results.map((r) => TaskGroup.fromMap(r)).toList();
});

// Tasks by group provider
final tasksByGroupProvider = FutureProvider.family<List<MiniTask>, int?>((ref, groupId) async {
  final db = await ref.watch(databaseProvider.future);
  
  if (groupId == null) {
    final results = await db.query(
      'mini_tasks',
      where: 'parent_task_id IS NULL AND is_completed = ?',
      whereArgs: [0],
      orderBy: 'priority DESC, sort_order ASC',
    );
    return results.map((r) => MiniTask.fromMap(r)).toList();
  }
  
  final results = await db.query(
    'mini_tasks',
    where: 'parent_task_id = ?',
    whereArgs: [groupId],
    orderBy: 'sort_order ASC',
  );
  
  return results.map((r) => MiniTask.fromMap(r)).toList();
});

class MiniTaskRepository {
  final dynamic db;
  
  MiniTaskRepository(this.db);
  
  Future<int> createTask(MiniTask task) async {
    return await db.insert('mini_tasks', task.toMap());
  }
  
  Future<void> updateTask(MiniTask task) async {
    await db.update('mini_tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }
  
  Future<void> deleteTask(int id) async {
    // Delete subtasks first
    await db.delete('mini_tasks', where: 'parent_task_id = ?', whereArgs: [id]);
    await db.delete('mini_tasks', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> toggleComplete(int taskId) async {
    final task = await db.query('mini_tasks', where: 'id = ?', whereArgs: [taskId]);
    if (task.isEmpty) return;
    
    final isCompleted = (task.first['is_completed'] as int? ?? 0) == 1;
    await db.update(
      'mini_tasks',
      {
        'is_completed': isCompleted ? 0 : 1,
        'completed_at': isCompleted ? null : DateTime.now().toIso8601String(),
        'status': isCompleted ? 'pending' : 'completed',
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
  
  Future<void> updateProgress(int taskId, int actualMinutes) async {
    await db.update(
      'mini_tasks',
      {'actual_minutes': actualMinutes},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
  
  Future<int> createTaskGroup(TaskGroup group) async {
    return await db.insert('task_groups', group.toMap());
  }
  
  Future<void> deleteTaskGroup(int id) async {
    await db.delete('mini_tasks', where: 'parent_task_id = ?', whereArgs: [id]);
    await db.delete('task_groups', where: 'id = ?', whereArgs: [id]);
  }
}