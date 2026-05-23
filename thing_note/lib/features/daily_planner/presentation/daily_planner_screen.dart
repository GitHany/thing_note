import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_planner/data/daily_planner_repository.dart';
import 'package:thing_note/features/daily_planner/domain/daily_task.dart';

class DailyPlannerScreen extends ConsumerStatefulWidget {
  const DailyPlannerScreen({super.key});

  @override
  ConsumerState<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends ConsumerState<DailyPlannerScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _dateString {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildTaskList(tasks);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(7, (i) {
      return now.add(Duration(days: i - 3));
    });

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('今日暂无任务', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<DailyTask> tasks) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('待完成 (${pending.length})'),
          ...pending.map((t) => _TaskCard(task: t, onToggle: () => _toggleTask(t.id!))),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader('已完成 (${completed.length})'),
          ...completed.map((t) => _TaskCard(task: t, onToggle: () => _toggleTask(t.id!))),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  void _toggleTask(int taskId) {
    ref.read(todayTasksProvider.notifier).toggleCompletion(taskId);
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    TaskPriority priority = TaskPriority.medium;
    String? timeSlot;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '任务标题'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskPriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: '优先级'),
                  items: TaskPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(p.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(p.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => priority = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: timeSlot,
                  decoration: const InputDecoration(labelText: '时间段（可选）'),
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('上午')),
                    DropdownMenuItem(value: 'afternoon', child: Text('下午')),
                    DropdownMenuItem(value: 'evening', child: Text('晚上')),
                  ],
                  onChanged: (v) => setState(() => timeSlot = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final task = DailyTask(
                    title: titleController.text.trim(),
                    date: _dateString,
                    priority: priority,
                    timeSlot: timeSlot,
                    createdAt: DateTime.now(),
                  );
                  ref.read(todayTasksProvider.notifier).addTask(task);
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onToggle;

  const _TaskCard({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(task.priority.colorValue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  task.isCompleted ? Icons.check : Icons.radio_button_unchecked,
                  color: task.isCompleted ? Colors.green : Color(task.priority.colorValue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (task.timeSlot != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeSlotText(task.timeSlot!),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(task.priority.colorValue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(task.priority.colorValue),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeSlotText(String slot) {
    switch (slot) {
      case 'morning':
        return '上午';
      case 'afternoon':
        return '下午';
      case 'evening':
        return '晚上';
      default:
        return slot;
    }
  }
}