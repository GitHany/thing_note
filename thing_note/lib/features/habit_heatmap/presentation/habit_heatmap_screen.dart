import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_heatmap/data/heatmap_repository.dart';
import 'package:thing_note/features/habit_heatmap/domain/habit_heatmap.dart';

class HabitHeatmapScreen extends ConsumerWidget {
  const HabitHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯热力图'),
      ),
      body: FutureBuilder<HeatmapStats>(
        future: ref.read(heatmapRepositoryProvider).getStatsForHabit(1),
        builder: (context, snapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('过去一年', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('每日习惯完成热力图', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                _buildHeatmapGrid(),
                const SizedBox(height: 16),
                _buildLegend(),
                const SizedBox(height: 24),
                _buildStats(snapshot.data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    // 生成过去365天的热力图
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 364));
    final weeks = <List<DateTime>>[];
    var current = start;
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }
    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 星期标签
          Column(
            children: [
              const SizedBox(height: 0),
              for (final label in ['一', '', '三', '', '五', '', '日'])
                SizedBox(
                  height: 13,
                  child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ),
            ],
          ),
          // 热力块
          for (final week in weeks)
            Column(
              children: [
                for (final day in week)
                  _HeatmapCell(
                    date: day,
                    level: _getLevelForDate(day),
                    isFuture: day.isAfter(now),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  int _getLevelForDate(DateTime date) {
    // 模拟数据：随机生成完成等级
    final hash = date.year * 365 + date.month * 31 + date.day;
    return hash % 5;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('无记录', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 4),
        for (final level in [0, 1, 2, 3, 4])
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _levelColor(level),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 4),
        const Text('完美', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStats(HeatmapStats? stats) {
    if (stats == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: '活跃天数', value: '${stats.activeDays}'),
                _StatItem(label: '当前连续', value: '${stats.currentStreak}'),
                _StatItem(label: '最佳连续', value: '${stats.longestStreak}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(int level) {
    switch (level) {
      case 0: return Colors.grey.shade200;
      case 1: return Colors.green.shade200;
      case 2: return Colors.green.shade400;
      case 3: return Colors.green.shade600;
      case 4: return Colors.green.shade800;
      default: return Colors.grey.shade200;
    }
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime date;
  final int level;
  final bool isFuture;

  const _HeatmapCell({required this.date, required this.level, required this.isFuture});

  @override
  Widget build(BuildContext context) {
    final color = isFuture
        ? Colors.transparent
        : _levelColor(level);
    return Tooltip(
      message: '${date.year}-${date.month}-${date.day}',
      child: Container(
        width: 11,
        height: 11,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Color _levelColor(int level) {
    switch (level) {
      case 0: return Colors.grey.shade200;
      case 1: return Colors.green.shade200;
      case 2: return Colors.green.shade400;
      case 3: return Colors.green.shade600;
      case 4: return Colors.green.shade800;
      default: return Colors.grey.shade200;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
