import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/recurring_tasks/data/recurring_tasks_provider.dart';
import 'package:thing_note/features/recurring_tasks/domain/recurring_task.dart';

class RecurringTasksScreen extends ConsumerStatefulWidget {
  const RecurringTasksScreen({super.key});

  @override
  ConsumerState<RecurringTasksScreen> createState() => _RecurringTasksScreenState();
}

class _RecurringTasksScreenState extends ConsumerState<RecurringTasksScreen> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(recurringTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周期性任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(context),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无周期性任务', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击右上角添加', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final overdueTasks = tasks.where((t) => t.isOverdue).toList();
          final todayTasks = tasks.where((t) => !t.isOverdue).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdueTasks.isNotEmpty) ...[
                _buildSectionHeader('已逾期', overdueTasks.length, Colors.red),
                ...overdueTasks.map((t) => _buildTaskCard(t, isOverdue: true)),
                const SizedBox(height: 16),
              ],
              _buildSectionHeader('今日任务', todayTasks.length, Colors.blue),
              ...todayTasks.map((t) => _buildTaskCard(t)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(RecurringTask task, {bool isOverdue = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTaskDetailDialog(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: isOverdue ? TextDecoration.lineThrough : null,
                        color: isOverdue ? Colors.grey : null,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(task.repeatTypeLabel, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('${task.currentStreak}天', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: task.bestStreak > 0 ? task.currentStreak / task.bestStreak : 0,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${task.completedCount}次完成',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _skipTask(task),
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('跳过'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _completeTask(task),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('完成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    Color color;
    String label;
    switch (priority) {
      case 1:
        color = Colors.grey;
        label = '低';
        break;
      case 3:
        color = Colors.orange;
        label = '高';
        break;
      case 4:
        color = Colors.red;
        label = '紧急';
        break;
      default:
        color = Colors.blue;
        label = '中';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Future<void> _completeTask(RecurringTask task) async {
    await ref.read(recurringTasksProvider.notifier).completeTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务完成！')),
      );
    }
  }

  Future<void> _skipTask(RecurringTask task) async {
    await ref.read(recurringTasksProvider.notifier).skipTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已跳过')),
      );
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String repeatType = 'daily';
    int priority = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('创建周期性任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '任务名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: repeatType,
                  decoration: const InputDecoration(
                    labelText: '重复类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('每日')),
                    DropdownMenuItem(value: 'weekly', child: Text('每周')),
                    DropdownMenuItem(value: 'monthly', child: Text('每月')),
                    DropdownMenuItem(value: 'yearly', child: Text('每年')),
                  ],
                  onChanged: (v) => setState(() => repeatType = v ?? 'daily'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: '优先级',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('低')),
                    DropdownMenuItem(value: 2, child: Text('中')),
                    DropdownMenuItem(value: 3, child: Text('高')),
                    DropdownMenuItem(value: 4, child: Text('紧急')),
                  ],
                  onChanged: (v) => setState(() => priority = v ?? 2),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final now = DateTime.now().toIso8601String();
                  final task = RecurringTask(
                    title: titleController.text,
                    description: descController.text.isNotEmpty ? descController.text : null,
                    repeatType: repeatType,
                    priority: priority,
                    createdAt: now,
                    updatedAt: now,
                    nextDueAt: now,
                  );
                  await ref.read(recurringTasksProvider.notifier).addTask(task);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailDialog(RecurringTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('重复类型', task.repeatTypeLabel),
            _buildInfoRow('连续天数', '${task.currentStreak}天'),
            _buildInfoRow('最佳记录', '${task.bestStreak}天'),
            _buildInfoRow('完成次数', '${task.completedCount}次'),
            _buildInfoRow('跳过次数', '${task.skippedCount}次'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(recurringTasksProvider.notifier).deleteTask(task.id!);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}