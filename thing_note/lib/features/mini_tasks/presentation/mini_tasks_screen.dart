import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mini_tasks/data/mini_task_provider.dart';
import 'package:thing_note/features/mini_tasks/domain/mini_task_models.dart';

class MiniTasksScreen extends ConsumerStatefulWidget {
  const MiniTasksScreen({super.key});

  @override
  ConsumerState<MiniTasksScreen> createState() => _MiniTasksScreenState();
}

class _MiniTasksScreenState extends ConsumerState<MiniTasksScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allPendingTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('微任务'),
        actions: [
          IconButton(
            icon: Icon(_showCompleted ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            tooltip: _showCompleted ? '隐藏已完成' : '显示已完成',
          ),
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () => _showCreateGroupDialog(context),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
          final completedTasks = tasks.where((t) => t.isCompleted).toList();
          
          if (pendingTasks.isEmpty && completedTasks.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allPendingTasksProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingTasks.isNotEmpty) ...[
                  _buildStatsCard(pendingTasks.length, completedTasks.length),
                  const SizedBox(height: 16),
                  Text(
                    '待办任务 (${pendingTasks.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...pendingTasks.map((task) => _TaskCard(task: task)),
                ],
                if (_showCompleted && completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    '已完成 (${completedTasks.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...completedTasks.map((task) => _TaskCard(task: task, isCompleted: true)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有任务',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '将大任务分解成小步骤，更容易完成',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加第一个任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int pending, int completed) {
    final total = pending + completed;
    final completionRate = total > 0 ? completed / total : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('待办', pending.toString(), Colors.blue),
                _buildStatItem('已完成', completed.toString(), Colors.green),
                _buildStatItem('完成率', '${(completionRate * 100).toStringAsFixed(0)}%', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int priority = 2;
    int estimatedMinutes = 15;
    String? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加微任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '任务标题',
                    hintText: '例如：整理文件夹',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: priority,
                        decoration: const InputDecoration(labelText: '优先级'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('低')),
                          DropdownMenuItem(value: 2, child: Text('中')),
                          DropdownMenuItem(value: 3, child: Text('高')),
                          DropdownMenuItem(value: 4, child: Text('紧急')),
                        ],
                        onChanged: (v) => setState(() => priority = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: estimatedMinutes,
                        decoration: const InputDecoration(labelText: '预估时间'),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5分钟')),
                          DropdownMenuItem(value: 15, child: Text('15分钟')),
                          DropdownMenuItem(value: 30, child: Text('30分钟')),
                          DropdownMenuItem(value: 60, child: Text('1小时')),
                        ],
                        onChanged: (v) => setState(() => estimatedMinutes = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final task = MiniTask(
                  title: titleController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  priority: priority,
                  estimatedMinutes: estimatedMinutes,
                  dueDate: dueDate,
                );
                await db.insert('mini_tasks', task.toMap());
                if (!mounted) return;
                Navigator.pop(context);
                ref.invalidate(allPendingTasksProvider);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建任务组'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '组名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.insert('task_groups', {
                'title': titleController.text,
                'description': descController.text.isEmpty ? null : descController.text,
                'created_at': DateTime.now().toIso8601String(),
              });
              if (!mounted) return;
              Navigator.pop(context);
              ref.invalidate(taskGroupsProvider);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final MiniTask task;
  final bool isCompleted;

  const _TaskCard({required this.task, this.isCompleted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = _getPriorityColor(task.priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: GestureDetector(
          onTap: () async {
            final db = await ref.read(databaseProvider.future);
            await db.update(
              'mini_tasks',
              {
                'is_completed': task.isCompleted ? 0 : 1,
                'completed_at': task.isCompleted ? null : DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [task.id],
            );
            ref.invalidate(allPendingTasksProvider);
          },
          child: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPriorityLabel(task.priority),
                    style: TextStyle(fontSize: 10, color: priorityColor),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${task.estimatedMinutes}分钟',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              final db = await ref.read(databaseProvider.future);
              await db.delete('mini_tasks', where: 'id = ?', whereArgs: [task.id]);
              ref.invalidate(allPendingTasksProvider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return '低';
      case 2:
        return '中';
      case 3:
        return '高';
      case 4:
        return '紧急';
      default:
        return '中';
    }
  }
}