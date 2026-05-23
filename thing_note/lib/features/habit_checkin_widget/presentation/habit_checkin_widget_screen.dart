import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_checkin_widget/data/habit_checkin_widget_provider.dart';
import 'package:thing_note/features/habit_checkin_widget/domain/habit_checkin_widget_provider.dart';

class HabitCheckinWidgetScreen extends ConsumerWidget {
  const HabitCheckinWidgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayHabitsAsync = ref.watch(todayHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯打卡小部件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHabitDialog(context, ref),
          ),
        ],
      ),
      body: todayHabitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  const Text('今日暂无习惯'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showAddHabitDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('添加习惯'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            itemBuilder: (context, index) => _buildHabitCard(context, ref, habits[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, WidgetRef ref, HabitCheckin habit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => ref.read(habitCheckinNotifierProvider.notifier).toggleCheckin(habit.id, !habit.isCompletedToday),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: habit.isCompletedToday
                  ? Colors.green
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
child: Icon(
              habit.isCompletedToday ? Icons.check : Icons.circle_outlined,
              color: habit.isCompletedToday ? Colors.white : Theme.of(context).disabledColor,
            ),
          ),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: habit.isCompletedToday ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text('${habit.streak}天连续'),
          ],
        ),
        trailing: CircularProgressIndicator(
          value: habit.completionRate / 100,
          backgroundColor: Theme.of(context).disabledColor.withOpacity( 0.3),
          color: _getCompletionColor(habit.completionRate),
        ),
      ),
    );
  }

  Color _getCompletionColor(int rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showAddHabitDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加习惯'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '习惯名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(habitCheckinNotifierProvider.notifier).addHabit(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}