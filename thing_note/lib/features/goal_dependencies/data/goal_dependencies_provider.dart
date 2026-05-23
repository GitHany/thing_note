// Goal Dependencies Visualization feature
// Version: 1.0
// Description: 可视化目标之间的依赖关系，帮助识别关键路径和阻塞因素

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Goal Dependencies Provider
final goalDependenciesProvider = FutureProvider<List<GoalDependency>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'goal_dependencies',
    orderBy: 'created_at DESC',
  );
  
  return maps.map((map) => GoalDependency.fromMap(map)).toList();
});

final goalGraphProvider = FutureProvider<GoalGraph>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // Get all goals
  final goals = await db.query('goals', orderBy: 'created_at DESC');
  
  // Build dependency graph
  final Map<int, List<int>> dependencies = {};
  final Map<int, List<int>> dependents = {};
  
  for (final goal in goals) {
    final goalId = goal['id'] as int;
    final dependsOn = goal['depends_on'] as int?;
    
    if (dependsOn != null) {
      dependencies[goalId] = [...(dependencies[goalId] ?? []), dependsOn];
      dependents[dependsOn] = [...(dependents[dependsOn] ?? []), goalId];
    }
  }
  
  // Find critical paths
  final criticalPaths = _findCriticalPaths(goals, dependencies);
  
  // Calculate levels for each goal
  final levels = _calculateLevels(goals, dependencies);
  
  return GoalGraph(
    goals: goals.map((g) => GoalNode.fromMap(g, levels[g['id'] as int] ?? 0)).toList(),
    dependencies: dependencies,
    dependents: dependents,
    criticalPaths: criticalPaths,
  );
});

class GoalDependency {
  final int? id;
  final int goalId;
  final int dependsOnGoalId;
  final String? note;
  final String createdAt;

  GoalDependency({
    this.id,
    required this.goalId,
    required this.dependsOnGoalId,
    this.note,
    required this.createdAt,
  });

  factory GoalDependency.fromMap(Map<String, dynamic> map) {
    return GoalDependency(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      dependsOnGoalId: map['depends_on_goal_id'] as int,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'depends_on_goal_id': dependsOnGoalId,
      'note': note,
      'created_at': createdAt,
    };
  }
}

class GoalGraph {
  final List<GoalNode> goals;
  final Map<int, List<int>> dependencies;
  final Map<int, List<int>> dependents;
  final List<List<int>> criticalPaths;

  GoalGraph({
    required this.goals,
    required this.dependencies,
    required this.dependents,
    required this.criticalPaths,
  });
}

class GoalNode {
  final int id;
  final String title;
  final int level;
  final String status;
  final double progress;

  GoalNode({
    required this.id,
    required this.title,
    required this.level,
    required this.status,
    required this.progress,
  });

  factory GoalNode.fromMap(Map<String, dynamic> map, int level) {
    return GoalNode(
      id: map['id'] as int,
      title: map['title'] as String? ?? '未命名目标',
      level: level,
      status: map['status'] as String? ?? 'active',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

List<List<int>> _findCriticalPaths(
  List<Map<String, dynamic>> goals,
  Map<int, List<int>> dependencies,
) {
  // Simple critical path detection using DFS
  final paths = <List<int>>[];
  
  for (final goal in goals) {
    final goalId = goal['id'] as int;
    if (!dependencies.containsKey(goalId)) {
      // Start of a path
      final path = _tracePath(goalId, dependencies, goals);
      if (path.length > 1) {
        paths.add(path);
      }
    }
  }
  
  return paths;
}

List<int> _tracePath(
  int startId,
  Map<int, List<int>> dependencies,
  List<Map<String, dynamic>> goals,
) {
  final path = <int>[startId];
  var currentId = startId;
  
  while (dependencies.containsKey(currentId)) {
    final deps = dependencies[currentId]!;
    if (deps.isEmpty) break;
    
    final nextId = deps.first;
    path.add(nextId);
    currentId = nextId;
  }
  
  return path;
}

Map<int, int> _calculateLevels(
  List<Map<String, dynamic>> goals,
  Map<int, List<int>> dependencies,
) {
  final levels = <int, int>{};
  
  for (final goal in goals) {
    final goalId = goal['id'] as int;
    levels[goalId] = _calculateLevel(goalId, dependencies, levels, {});
  }
  
  return levels;
}

int _calculateLevel(
  int goalId,
  Map<int, List<int>> dependencies,
  Map<int, int> levels,
  Map<int, int> visited,
) {
  if (visited.containsKey(goalId)) return 0;
  visited[goalId] = 1;
  
  final deps = dependencies[goalId] ?? [];
  if (deps.isEmpty) return 0;
  
  int maxDepLevel = 0;
  for (final depId in deps) {
    maxDepLevel = max(maxDepLevel, levels[depId] ?? _calculateLevel(depId, dependencies, levels, {}));
  }
  
  return maxDepLevel + 1;
}

int max(int a, int b) => a > b ? a : b;