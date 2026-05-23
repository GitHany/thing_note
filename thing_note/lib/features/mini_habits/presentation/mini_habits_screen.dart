import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mini_habits/data/mini_habits_repository.dart';
import 'package:thing_note/features/mini_habits/domain/mini_habit.dart';

class MiniHabitsScreen extends ConsumerWidget {
  const MiniHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(miniHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('迷你习惯'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
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
                  const Icon(Icons.flash_on, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text('2分钟以内的小习惯', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('建立微习惯，降低启动阻力', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
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
            itemBuilder: (context, index) => _MiniHabitCard(habit: habits[index]),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int duration = 120;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新建迷你习惯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '习惯名称', hintText: '例如：喝杯水')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述 (可选)'), maxLines: 2),
                const SizedBox(height: 12),
                const Text('预计时长:'),
                Wrap(
                  spacing: 8,
                  children: [30, 60, 120, 180, 300].map((s) {
                    final label = s < 60 ? '$s秒' : '${s ~/ 60}分钟';
                    return ChoiceChip(
                      label: Text(label),
                      selected: duration == s,
                      onSelected: (_) => setState(() => duration = s),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final now = DateTime.now();
                final habit = MiniHabit(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  durationSeconds: duration,
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(miniHabitsProvider.notifier).addHabit(habit);
                Navigator.pop(ctx);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniHabitCard extends ConsumerWidget {
  final MiniHabit habit;
  const _MiniHabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(habit.color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      habit.isOnFire ? Icons.local_fire_department : Icons.flash_on,
                      color: habit.isOnFire ? Colors.deepOrange : Colors.amber,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (habit.description != null)
                        Text(habit.description!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(label: habit.durationLabel, icon: Icons.timer),
                const SizedBox(width: 8),
                _StatChip(label: '${habit.streakDays}天', icon: Icons.local_fire_department, color: habit.isOnFire ? Colors.deepOrange : Colors.grey),
                const SizedBox(width: 8),
                _StatChip(label: '最高${habit.bestStreak}天', icon: Icons.emoji_events, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(miniHabitsProvider.notifier).completeHabit(habit.id!);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('完成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(habit.color),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(miniHabitsProvider.notifier).deleteHabit(habit.id!);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _StatChip({required this.label, required this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (color ?? Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey.shade700)),
        ],
      ),
    );
  }
}
