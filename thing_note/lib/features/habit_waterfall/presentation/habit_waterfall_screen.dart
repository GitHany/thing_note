import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Habit Waterfall View State
class HabitWaterfallItem {
  final String habitId;
  final String habitName;
  final Color color;
  final List<DateTime> completionDates;
  final int currentStreak;
  final int longestStreak;

  HabitWaterfallItem({
    required this.habitId,
    required this.habitName,
    required this.color,
    required this.completionDates,
    required this.currentStreak,
    required this.longestStreak,
  });
}

final habitWaterfallProvider = FutureProvider<List<HabitWaterfallItem>>((ref) async {
  // Simulated data
  final now = DateTime.now();
  return [
    HabitWaterfallItem(
      habitId: '1',
      habitName: '早起',
      color: Colors.blue,
      completionDates: List.generate(30, (i) => now.subtract(Duration(days: i)))
          .where((d) => d.day % 2 == 0 || d.day % 3 == 0)
          .toList(),
      currentStreak: 5,
      longestStreak: 12,
    ),
    HabitWaterfallItem(
      habitId: '2',
      habitName: '运动',
      color: Colors.green,
      completionDates: List.generate(30, (i) => now.subtract(Duration(days: i)))
          .where((d) => d.day % 3 == 0)
          .toList(),
      currentStreak: 3,
      longestStreak: 8,
    ),
    HabitWaterfallItem(
      habitId: '3',
      habitName: '阅读',
      color: Colors.orange,
      completionDates: List.generate(30, (i) => now.subtract(Duration(days: i)))
          .where((d) => d.day % 2 == 0)
          .toList(),
      currentStreak: 7,
      longestStreak: 15,
    ),
    HabitWaterfallItem(
      habitId: '4',
      habitName: '冥想',
      color: Colors.purple,
      completionDates: List.generate(30, (i) => now.subtract(Duration(days: i)))
          .where((d) => d.weekday != 7 && d.day % 2 == 0)
          .toList(),
      currentStreak: 2,
      longestStreak: 6,
    ),
    HabitWaterfallItem(
      habitId: '5',
      habitName: '写作',
      color: Colors.red,
      completionDates: List.generate(30, (i) => now.subtract(Duration(days: i)))
          .where((d) => d.day % 5 == 0)
          .toList(),
      currentStreak: 0,
      longestStreak: 4,
    ),
  ];
});

class HabitWaterfallScreen extends ConsumerStatefulWidget {
  const HabitWaterfallScreen({super.key});

  @override
  ConsumerState<HabitWaterfallScreen> createState() => _HabitWaterfallScreenState();
}

class _HabitWaterfallScreenState extends ConsumerState<HabitWaterfallScreen> {
  int _viewMode = 0; // 0: Week, 1: Month, 2: Year
  int _daysToShow = 7;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitWaterfallProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯瀑布流'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addHabit(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewModeSelector(),
          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('加载失败: $err')),
              data: (habits) => _buildWaterfallView(habits),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('周'),
            selected: _viewMode == 0,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _viewMode = 0;
                  _daysToShow = 7;
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('月'),
            selected: _viewMode == 1,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _viewMode = 1;
                  _daysToShow = 30;
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('年'),
            selected: _viewMode == 2,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _viewMode = 2;
                  _daysToShow = 365;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallView(List<HabitWaterfallItem> habits) {
    final now = DateTime.now();
    final dates = List.generate(_daysToShow, (i) => now.subtract(Duration(days: _daysToShow - 1 - i)));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Date headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 100, child: Text('习惯', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  child: _viewMode == 2
                      ? _buildYearHeaders(dates)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: dates.take(_viewMode == 0 ? 7 : 30).map((d) {
                            return SizedBox(
                              width: _viewMode == 0 ? 40 : 20,
                              child: Text(
                                _viewMode == 0 ? DateFormat('E').format(d).substring(0, 1) : DateFormat('d').format(d),
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Habit rows
          ...habits.map((habit) => _buildHabitRow(habit, dates)),
          const SizedBox(height: 16),
          _buildStatistics(habits),
        ],
      ),
    );
  }

  Widget _buildYearHeaders(List<DateTime> dates) {
    // Group by month for year view
    final months = <int, List<DateTime>>{};
    for (final date in dates) {
      months.putIfAbsent(date.month, () => []).add(date);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: months.entries.take(12).map((entry) {
        return SizedBox(
          width: 20,
          child: Text(
            DateFormat('M').format(entry.value.first),
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitRow(HabitWaterfallItem habit, List<DateTime> dates) {
    final completionSet = habit.completionDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.habitName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: habit.color),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${habit.currentStreak}天连续',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
          Expanded(
            child: _viewMode == 2
                ? _buildYearRow(habit, dates, completionSet)
                : Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.spaceEvenly,
                    children: dates.take(_viewMode == 0 ? 7 : 30).map((d) {
                      final dateKey = DateTime(d.year, d.month, d.day);
                      final isCompleted = completionSet.contains(dateKey);
                      return _buildCell(isCompleted, habit.color);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearRow(HabitWaterfallItem habit, List<DateTime> dates, Set<DateTime> completionSet) {
    // Simplified year view - show completion rate per month
    final months = <int, int>{};
    for (final date in dates) {
      final month = date.month;
      months[month] = (months[month] ?? 0) + (completionSet.contains(DateTime(date.year, date.month, date.day)) ? 1 : 0);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(12, (month) {
        final monthDates = dates.where((d) => d.month == month + 1).length;
        final completed = months[month + 1] ?? 0;
        final rate = monthDates > 0 ? completed / monthDates : 0.0;
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getIntensityColor(rate, habit.color),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildCell(bool isCompleted, Color color) {
    return Container(
      width: _viewMode == 0 ? 36 : 16,
      height: 36,
      decoration: BoxDecoration(
        color: isCompleted ? color : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }

  Color _getIntensityColor(double intensity, Color baseColor) {
    if (intensity == 0) return Colors.grey.withOpacity(0.2);
    if (intensity < 0.3) return baseColor.withOpacity(0.3);
    if (intensity < 0.6) return baseColor.withOpacity(0.6);
    if (intensity < 0.9) return baseColor.withOpacity(0.8);
    return baseColor;
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('完成度: '),
          const SizedBox(width: 4),
          Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          const Icon(Icons.horizontal_rule, size: 12),
          const SizedBox(width: 4),
          Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          const Icon(Icons.horizontal_rule, size: 12),
          const SizedBox(width: 4),
          Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          const Icon(Icons.check, color: Colors.white, size: 12),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<HabitWaterfallItem> habits) {
    final totalCompletions = habits.fold<int>(0, (sum, h) => sum + h.completionDates.length);
    final avgStreak = habits.isEmpty ? 0 : habits.fold<int>(0, (sum, h) => sum + h.currentStreak) ~/ habits.length;
    final bestStreak = habits.fold<int>(0, (best, h) => h.longestStreak > best ? h.longestStreak : best);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '统计概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('总完成次数', totalCompletions.toString(), Colors.blue)),
                Expanded(child: _buildStatItem('平均连续', '${avgStreak}天', Colors.green)),
                Expanded(child: _buildStatItem('最长连续', '${bestStreak}天', Colors.orange)),
              ],
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  void _addHabit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加习惯'),
        content: const TextField(
          decoration: InputDecoration(hintText: '习惯名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('添加')),
        ],
      ),
    );
  }
}
