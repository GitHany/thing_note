import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_goal_reset/data/weekly_goal_provider.dart';
import 'package:thing_note/features/weekly_goal_reset/domain/weekly_goal_model.dart';

class WeeklyGoalResetScreen extends ConsumerWidget {
  const WeeklyGoalResetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(weeklyGoalNotifierProvider);
    final statsAsync = ref.watch(weeklyResetStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每周目标重置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetGoals(context, ref),
            tooltip: '重置目标',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          statsAsync.when(
            data: (stats) => _buildStatsCard(context, stats),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Goals List
          Expanded(
            child: goalsAsync.when(
              data: (goals) => _buildGoalsList(context, ref, goals),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加目标'),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WeeklyResetStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('本周目标', '${stats.currentGoals.length}', Icons.flag),
              _buildStatItem('已完成', '${stats.currentGoals.where((g) => g.isCompleted).length}', Icons.check),
              _buildStatItem('平均完成', '${(stats.averageCompletion * 100).toInt()}%', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '本周进度: ${(stats.currentGoals.isEmpty ? 0 : stats.currentGoals.where((g) => g.isCompleted).length / stats.currentGoals.length * 100).toInt()}%',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGoalsList(BuildContext context, WidgetRef ref, List<WeeklyGoal> goals) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无本周目标',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击 + 添加新目标',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _buildGoalCard(context, ref, goal);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, WeeklyGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: goal.isCompleted ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.goalTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            if (goal.targetValue != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${goal.currentValue.toStringAsFixed(0)}/${goal.targetValue!.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showUpdateProgressDialog(context, ref, goal),
                  child: const Text('更新进度'),
                ),
                if (!goal.isCompleted)
                  TextButton(
                    onPressed: () => ref.read(weeklyGoalNotifierProvider.notifier).completeGoal(goal.id),
                    child: const Text('完成'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加周目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '目标名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(
                labelText: '目标值（可选）',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              if (titleController.text.isNotEmpty) {
                final target = double.tryParse(targetController.text);
                ref.read(weeklyGoalNotifierProvider.notifier).addGoal(
                  titleController.text,
                  target,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, WidgetRef ref, WeeklyGoal goal) {
    final controller = TextEditingController(text: goal.currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新进度'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '当前值',
            border: const OutlineInputBorder(),
            hintText: '目标: ${goal.targetValue ?? "无"}',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                ref.read(weeklyGoalNotifierProvider.notifier).updateProgress(goal.id, value);
                Navigator.pop(context);
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _resetGoals(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要重置所有目标吗？这将标记本周目标为已重置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(weeklyGoalNotifierProvider.notifier).resetGoals();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('目标已重置')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}