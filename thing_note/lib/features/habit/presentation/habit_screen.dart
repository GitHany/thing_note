import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit/data/habit_repository.dart';
import 'package:thing_note/features/habit/domain/habit.dart';

class HabitScreen extends ConsumerStatefulWidget {
  const HabitScreen({super.key});

  @override
  ConsumerState<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends ConsumerState<HabitScreen> {
  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHabitDialog(context),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.repeat, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无习惯', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddHabitDialog(context),
                    child: const Text('添加习惯'),
                  ),
                ],
              ),
            );
          }

          final completed = habits.where((h) => h.isCompletedToday).toList();
          final pending = habits.where((h) => !h.isCompletedToday).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (completed.isNotEmpty) ...[
                _buildSectionHeader('今日已完成 (${completed.length})'),
                ...completed.map((h) => _HabitCard(habit: h, isCompleted: true)),
                const SizedBox(height: 16),
              ],
              if (pending.isNotEmpty) ...[
                _buildSectionHeader('今日待完成 (${pending.length})'),
                ...pending.map((h) => _HabitCard(habit: h, isCompleted: false)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        child: const Icon(Icons.add),
      ),
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

  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    HabitFrequency frequency = HabitFrequency.daily;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加习惯'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '习惯名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述（可选）'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<HabitFrequency>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: '频率'),
                  items: HabitFrequency.values.map((f) {
                    return DropdownMenuItem(value: f, child: Text(f.displayName));
                  }).toList(),
                  onChanged: (v) => setState(() => frequency = v!),
                ),
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
              if (nameController.text.trim().isNotEmpty) {
                final habit = Habit(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  frequency: frequency,
                  createdAt: DateTime.now(),
                );
                ref.read(habitsProvider.notifier).addHabit(habit);
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

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;

  const _HabitCard({required this.habit, required this.isCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => isCompleted ? null : ref.read(habitsProvider.notifier).completeHabit(habit.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.flag,
                  color: isCompleted ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, size: 16, color: Colors.orange[400]),
                        const SizedBox(width: 4),
                        Text(
                          '连续 ${habit.currentStreak} 天',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.emoji_events, size: 16, color: Colors.amber[400]),
                        const SizedBox(width: 4),
                        Text(
                          '最佳 ${habit.bestStreak} 天',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () => ref.read(habitsProvider.notifier).completeHabit(habit.id!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('完成'),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}