import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/task_dependency/domain/task_dependency.dart';

class TaskDependencyScreen extends ConsumerWidget {
  const TaskDependencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksWithDependenciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务依赖管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () => _showCriticalPath(context, ref),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text('暂无任务'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _TaskDependencyCard(task: tasks[index]);
            },
          );
        },
      ),
    );
  }

  void _showCriticalPath(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(taskDependencyRepositoryProvider);
    final criticalPath = await repo.getCriticalPath();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关键路径'),
        content: Text(
          criticalPath.isEmpty 
              ? '无关键路径' 
              : '任务 IDs: ${criticalPath.join(" → ")}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _TaskDependencyCard extends StatelessWidget {
  final TaskWithDependencies task;

  const _TaskDependencyCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('阻塞', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (task.dependsOn.isNotEmpty) ...[
              const Text('依赖于:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: task.dependsOn.map((id) => Chip(
                  label: Text('任务 #$id'),
                  backgroundColor: Colors.blue.shade50,
                )).toList(),
              ),
            ],
            if (task.dependents.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('被依赖:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: task.dependents.map((id) => Chip(
                  label: Text('任务 #$id'),
                  backgroundColor: Colors.orange.shade50,
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(status: task.status ?? 'unknown'),
                const Spacer(),
                if (task.progress != null)
                  Text('进度: ${task.progress}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}