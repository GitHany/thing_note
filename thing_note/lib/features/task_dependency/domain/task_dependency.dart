import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TaskDependency {
  final int? id;
  final int taskId;
  final int dependsOnTaskId;
  final DateTime createdAt;

  TaskDependency({
    this.id,
    required this.taskId,
    required this.dependsOnTaskId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'depends_on_task_id': dependsOnTaskId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskDependency.fromMap(Map<String, dynamic> map) {
    return TaskDependency(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      dependsOnTaskId: map['depends_on_task_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class TaskWithDependencies {
  final int id;
  final String title;
  final String? status;
  final int? progress;
  final List<int> dependsOn;
  final List<int> dependents;
  final int depth; // Critical path depth
  final bool isBlocked;

  TaskWithDependencies({
    required this.id,
    required this.title,
    this.status,
    this.progress,
    this.dependsOn = const [],
    this.dependents = const [],
    this.depth = 0,
    this.isBlocked = false,
  });
}

class TaskDependencyRepository {
  final Database _db;

  TaskDependencyRepository(this._db);

  Future<int> insert(TaskDependency dependency) async {
    return _db.insert('task_dependencies', dependency.toMap()..remove('id'));
  }

  Future<int> delete(int id) async {
    return _db.delete('task_dependencies', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TaskDependency>> getByTaskId(int taskId) async {
    final results = await _db.query(
      'task_dependencies',
      where: 'task_id = ? OR depends_on_task_id = ?',
      whereArgs: [taskId, taskId],
    );
    return results.map((e) => TaskDependency.fromMap(e)).toList();
  }

  Future<List<TaskWithDependencies>> getTasksWithDependencies() async {
    // Get all goals (tasks)
    final goals = await _db.query('goals');
    // Get all dependencies
    final dependencies = await _db.query('task_dependencies');

    // Build dependency map
    final dependsOnMap = <int, List<int>>{};
    final dependentsMap = <int, List<int>>{};

    for (final dep in dependencies) {
      final taskId = dep['task_id'] as int;
      final dependsOn = dep['depends_on_task_id'] as int;

      dependsOnMap.putIfAbsent(taskId, () => []).add(dependsOn);
      dependentsMap.putIfAbsent(dependsOn, () => []).add(taskId);
    }

    // Calculate depths and blocked status
    final taskWithDeps = <TaskWithDependencies>[];
    for (final goal in goals) {
      final taskId = goal['id'] as int;
      final dependsOn = dependsOnMap[taskId] ?? [];
      final dependents = dependentsMap[taskId] ?? [];

      // Check if blocked (any dependency not completed)
      bool isBlocked = false;
      for (final depId in dependsOn) {
        final depGoal = goals.firstWhere(
          (g) => g['id'] == depId,
          orElse: () => {},
        );
        if (depGoal.isNotEmpty && depGoal['status'] != 'completed') {
          isBlocked = true;
          break;
        }
      }

      // Calculate depth
      int depth = 0;
      for (final depId in dependsOn) {
        final depTasks = taskWithDeps.where((t) => t.id == depId);
        if (depTasks.isNotEmpty) {
          depth = depth > depTasks.first.depth + 1 ? depth : depTasks.first.depth + 1;
        }
      }

      taskWithDeps.add(TaskWithDependencies(
        id: taskId,
        title: goal['title'] as String? ?? '',
        status: goal['status'] as String?,
        progress: goal['current_progress'] as int?,
        dependsOn: dependsOn,
        dependents: dependents,
        depth: depth,
        isBlocked: isBlocked,
      ));
    }

    return taskWithDeps;
  }

  Future<void> addDependency(int taskId, int dependsOnTaskId) async {
    // Check for circular dependency
    if (await _wouldCreateCycle(taskId, dependsOnTaskId)) {
      throw Exception('添加此依赖会创建循环依赖');
    }
    await insert(TaskDependency(
      taskId: taskId,
      dependsOnTaskId: dependsOnTaskId,
      createdAt: DateTime.now(),
    ));
  }

  Future<bool> _wouldCreateCycle(int taskId, int dependsOnTaskId) async {
    final existing = await getByTaskId(dependsOnTaskId);
    final visited = <int>{};
    final queue = [taskId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == dependsOnTaskId) return true;
      if (visited.contains(current)) continue;
      visited.add(current);

      for (final dep in existing) {
        if (dep.taskId == current) {
          queue.add(dep.dependsOnTaskId);
        }
      }
    }

    return false;
  }

  Future<List<int>> getCriticalPath() async {
    final tasks = await getTasksWithDependencies();
    if (tasks.isEmpty) return [];

    // Find tasks with no dependencies (start points)
    final startTasks = tasks.where((t) => t.dependsOn.isEmpty).toList();
    if (startTasks.isEmpty) return [];

    // Find longest path
    List<int> longestPath = [];
    for (final start in startTasks) {
      final path = _findLongestPath(start, tasks);
      if (path.length > longestPath.length) {
        longestPath = path;
      }
    }

    return longestPath;
  }

  List<int> _findLongestPath(TaskWithDependencies task, List<TaskWithDependencies> allTasks) {
    if (task.dependents.isEmpty) return [task.id];

    List<int> longestSubPath = [];
    for (final depId in task.dependents) {
      final depTask = allTasks.firstWhere(
        (t) => t.id == depId,
        orElse: () => task,
      );
      if (depTask.id == task.id) continue;
      final subPath = _findLongestPath(depTask, allTasks);
      if (subPath.length > longestSubPath.length) {
        longestSubPath = subPath;
      }
    }

    return [task.id, ...longestSubPath];
  }
}

final taskDependencyRepositoryProvider = Provider<TaskDependencyRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return TaskDependencyRepository(db);
});

final tasksWithDependenciesProvider = FutureProvider<List<TaskWithDependencies>>((ref) async {
  final repo = ref.watch(taskDependencyRepositoryProvider);
  return repo.getTasksWithDependencies();
});