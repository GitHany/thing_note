import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/goal_dependencies/domain/goal_dependencies_model.dart';

/// Repository for Goal Dependencies data operations
class GoalDependenciesRepository {
  final Database db;

  GoalDependenciesRepository(this.db);

  /// Create a goal dependency
  Future<int> createDependency(GoalDependencyModel dependency) async {
    return await db.insert('goal_dependencies', dependency.toMap());
  }

  /// Delete a goal dependency
  Future<int> deleteDependency(int id) async {
    return await db.delete(
      'goal_dependencies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all dependencies for a goal
  Future<int> deleteDependenciesForGoal(int goalId) async {
    return await db.delete(
      'goal_dependencies',
      where: 'goal_id = ? OR depends_on_goal_id = ?',
      whereArgs: [goalId, goalId],
    );
  }

  /// Get all dependencies
  Future<List<GoalDependencyModel>> getAllDependencies() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'goal_dependencies',
    );
    return maps.map((map) => GoalDependencyModel.fromMap(map)).toList();
  }

  /// Get dependencies for a specific goal (both as source and target)
  Future<List<GoalDependencyModel>> getDependenciesForGoal(int goalId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'goal_dependencies',
      where: 'goal_id = ? OR depends_on_goal_id = ?',
      whereArgs: [goalId, goalId],
    );
    return maps.map((map) => GoalDependencyModel.fromMap(map)).toList();
  }

  /// Get direct dependencies (what this goal depends on)
  Future<List<GoalDependencyModel>> getDirectDependencies(int goalId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'goal_dependencies',
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    return maps.map((map) => GoalDependencyModel.fromMap(map)).toList();
  }

  /// Get dependents (what depends on this goal)
  Future<List<GoalDependencyModel>> getDependents(int goalId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'goal_dependencies',
      where: 'depends_on_goal_id = ?',
      whereArgs: [goalId],
    );
    return maps.map((map) => GoalDependencyModel.fromMap(map)).toList();
  }

  /// Check if adding a dependency would create a cycle
  Future<bool> wouldCreateCycle(int goalId, int dependsOnGoalId) async {
    // Simple cycle detection using BFS
    final visited = <int>{};
    final queue = <int>[dependsOnGoalId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == goalId) return true;
      if (visited.contains(current)) continue;
      
      visited.add(current);
      
      // Get dependencies of current goal
      final deps = await getDirectDependencies(current);
      for (final dep in deps) {
        queue.add(dep.dependsOnGoalId);
      }
    }

    return false;
  }

  /// Get dependency graph
  Future<Map<int, List<int>>> getDependencyGraph() async {
    final dependencies = await getAllDependencies();
    final graph = <int, List<int>>{};
    
    for (final dep in dependencies) {
      if (!graph.containsKey(dep.goalId)) {
        graph[dep.goalId] = [];
      }
      graph[dep.goalId]!.add(dep.dependsOnGoalId);
    }
    
    return graph;
  }

  /// Get reverse dependency graph (who depends on whom)
  Future<Map<int, List<int>>> getReverseDependencyGraph() async {
    final dependencies = await getAllDependencies();
    final graph = <int, List<int>>{};
    
    for (final dep in dependencies) {
      if (!graph.containsKey(dep.dependsOnGoalId)) {
        graph[dep.dependsOnGoalId] = [];
      }
      graph[dep.dependsOnGoalId]!.add(dep.goalId);
    }
    
    return graph;
  }

  /// Get goals that are blocked (dependencies not completed)
  Future<List<int>> getBlockedGoalIds() async {
    final dependencies = await getAllDependencies();
    final blockedGoalIds = <int>[];
    
    // Group dependencies by goal
    final goalDependencies = <int, List<int>>{};
    for (final dep in dependencies) {
      if (!goalDependencies.containsKey(dep.goalId)) {
        goalDependencies[dep.goalId] = [];
      }
      goalDependencies[dep.goalId]!.add(dep.dependsOnGoalId);
    }
    
    // Get all goals
    final goals = await db.query('goals');
    
    for (final goal in goals) {
      final goalId = goal['id'] as int;
      final status = goal['status'] as String?;
      
      if (status == 'in_progress' && goalDependencies.containsKey(goalId)) {
        // Check if any dependency is not completed
        for (final depId in goalDependencies[goalId]!) {
          final depGoal = goals.firstWhere(
            (g) => g['id'] == depId,
            orElse: () => {'status': 'completed'},
          );
          if (depGoal['status'] != 'completed') {
            blockedGoalIds.add(goalId);
            break;
          }
        }
      }
    }
    
    return blockedGoalIds;
  }

  /// Get dependency chain depth
  Future<int> getDependencyDepth(int goalId) async {
    final visited = <int>{};
    
    // Use iterative approach instead
    int maxDepth = 0;
    final queue = <(int, int)>[(goalId, 0)];
    
    while (queue.isNotEmpty) {
      final (id, currentDepth) = queue.removeLast();
      if (visited.contains(id)) continue;
      visited.add(id);
      
      final deps = await getDirectDependencies(id);
      if (deps.isEmpty) {
        if (currentDepth > maxDepth) maxDepth = currentDepth;
      } else {
        for (final dep in deps) {
          queue.add((dep.dependsOnGoalId, currentDepth + 1));
        }
      }
    }
    
    return maxDepth;
  }
}