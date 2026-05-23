import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_streak/data/habit_streak_repository.dart';
import 'package:thing_note/features/habit_streak/domain/habit_streak.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final habitStreakProvider = Provider((ref) => ref.watch(habitStreakRepositoryProvider));

class HabitStreakScreen extends ConsumerStatefulWidget {
  const HabitStreakScreen({super.key});

  @override
  ConsumerState<HabitStreakScreen> createState() => _HabitStreakScreenState();
}

class _HabitStreakScreenState extends ConsumerState<HabitStreakScreen> {
  List<HabitStreak> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final repo = ref.read(habitStreakProvider);
    _habits = await repo.getAll();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.habitStreak),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHabitDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHabits,
              child: _habits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('还没有习惯', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text('添加你的第一个习惯来开始连续打卡'),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _showAddHabitDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('添加习惯'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _habits.length,
                      itemBuilder: (context, index) {
                        final habit = _habits[index];
                        return _buildHabitCard(habit);
                      },
                    ),
            ),
    );
  }

  Widget _buildHabitCard(HabitStreak habit) {
    final isActive = habit.currentStreak > 0;
    final isFireStreak = habit.currentStreak >= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isFireStreak)
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 28)
                else
                  const Icon(Icons.check_circle_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.habitName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (habit.lastCheckIn != null)
                        Text(
                          '上次打卡: ${habit.lastCheckIn}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteHabit(habit.id!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StreakStat(
                  value: '${habit.currentStreak}',
                  label: '当前连续',
                  color: isActive ? Colors.orange : Colors.grey,
                  isHighlight: true,
                ),
                _StreakStat(
                  value: '${habit.longestStreak}',
                  label: '最长记录',
                  color: Colors.blue,
                ),
                _StreakStat(
                  value: habit.bestRecord ?? '-',
                  label: '最佳记录',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _checkIn(habit),
                icon: Icon(isActive ? Icons.add : Icons.play_arrow),
                label: Text(isActive ? '继续打卡' : '开始打卡'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加习惯'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '习惯名称',
            hintText: '例如：早起、跑步、阅读',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final habit = HabitStreak(habitName: nameController.text);
              await ref.read(habitStreakProvider).insert(habit);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadHabits();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkIn(HabitStreak habit) async {
    final updated = await ref.read(habitStreakProvider).checkIn(habit.id!);
    if (updated != null) {
      _loadHabits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                Text('打卡成功！连续 ${updated.currentStreak} 天'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteHabit(int id) async {
    await ref.read(habitStreakProvider).delete(id);
    _loadHabits();
  }
}

class _StreakStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isHighlight;

  const _StreakStat({
    required this.value,
    required this.label,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}