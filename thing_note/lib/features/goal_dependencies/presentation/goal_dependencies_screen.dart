import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/goal_dependencies/data/goal_dependencies_provider.dart';

class GoalDependenciesScreen extends ConsumerWidget {
  const GoalDependenciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphAsync = ref.watch(goalGraphProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标依赖关系'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDependencyDialog(context),
          ),
        ],
      ),
      body: graphAsync.when(
        data: (graph) => _buildGraphView(context, graph),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildGraphView(BuildContext context, GoalGraph graph) {
    if (graph.goals.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats
          _buildSummarySection(context, graph),
          const SizedBox(height: 24),
          
          // Critical Paths
          if (graph.criticalPaths.isNotEmpty) ...[
            _buildCriticalPathsSection(context, graph),
            const SizedBox(height: 24),
          ],
          
          // Goal List with Dependencies
          Text(
            '目标层级',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ..._buildGoalTree(context, graph),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无目标依赖',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '添加目标并设置依赖关系\n以查看依赖关系图',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, GoalGraph graph) {
    return Row(
      children: [
        _buildStatCard(
          context,
          '总目标',
          '${graph.goals.length}',
          Icons.flag,
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          '依赖关系',
          '${graph.dependencies.length}',
          Icons.link,
          Colors.purple,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          '关键路径',
          '${graph.criticalPaths.length}',
          Icons.trending_up,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalPathsSection(BuildContext context, GoalGraph graph) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              '关键路径',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '这些目标路径的延迟会影响整体进度',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...graph.criticalPaths.take(3).map((path) {
          return Card(
            color: Colors.orange.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path.map((id) => '目标$id').join(' → '),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${path.length}步',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildGoalTree(BuildContext context, GoalGraph graph) {
    // Group goals by level
    final Map<int, List<GoalNode>> levelGroups = {};
    for (final goal in graph.goals) {
      levelGroups.putIfAbsent(goal.level, () => []).add(goal);
    }
    
    final widgets = <Widget>[];
    final sortedLevels = levelGroups.keys.toList()..sort();
    
    for (final level in sortedLevels) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: 16.0 * level),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (level > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '层级 $level',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
              ...levelGroups[level]!.map((goal) {
                final hasDeps = graph.dependencies.containsKey(goal.id);
                final isDependedOn = graph.dependents.containsKey(goal.id);
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(goal.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${goal.level}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(goal.status),
                          ),
                        ),
                      ),
                    ),
                    title: Text(goal.title),
                    subtitle: Row(
                      children: [
                        _buildMiniChip(
                          '${(goal.progress * 100).toInt()}%',
                          Colors.green,
                        ),
                        if (hasDeps) ...[
                          const SizedBox(width: 8),
                          _buildMiniChip(
                            '依赖${graph.dependencies[goal.id]!.length}',
                            Colors.purple,
                          ),
                        ],
                        if (isDependedOn) ...[
                          const SizedBox(width: 8),
                          _buildMiniChip(
                            '被${graph.dependents[goal.id]!.length}依赖',
                            Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    trailing: Icon(
                      hasDeps ? Icons.subdirectory_arrow_right : Icons.move_down,
                      color: Colors.grey,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAddDependencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加依赖关系'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选择需要设置依赖的目标'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '目标A（依赖者）',
                hintText: '选择目标',
              ),
            ),
            SizedBox(height: 8),
            Icon(Icons.arrow_downward),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: '目标B（被依赖）',
                hintText: '选择目标',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('依赖关系已添加')),
              );
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}