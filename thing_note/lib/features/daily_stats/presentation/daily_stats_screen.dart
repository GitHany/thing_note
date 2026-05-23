import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_stats/data/daily_stats_repository.dart';
import 'package:thing_note/features/daily_stats/domain/daily_stats_snapshot.dart';

class DailyStatsScreen extends ConsumerWidget {
  const DailyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(dailyStatsTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showWeeklyView(context, ref),
          ),
        ],
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (stats) => _buildContent(context, ref, stats),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DailyStatsSnapshot? stats) {
    final data = stats ?? _defaultStats();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日概览', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // 核心指标卡片
          Row(
            children: [
              Expanded(child: _StatCard(label: '记录数', value: '${data.recordsCount}', icon: Icons.list, color: Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '总时长', value: '${data.totalDurationMinutes}分钟', icon: Icons.timer, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(label: '习惯完成', value: '${data.habitsCompleted}/${data.habitsTotal}', icon: Icons.check_circle, color: Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '目标完成', value: '${data.goalsCompleted}', icon: Icons.flag, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          // 心情能量
          if (data.moodScore != null || data.energyScore != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (data.moodScore != null) _MoodEnergyItem(label: '心情', value: data.moodScore!, icon: Icons.mood),
                    if (data.energyScore != null) _MoodEnergyItem(label: '精力', value: data.energyScore!, icon: Icons.bolt),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // 常用事情
          if (data.topThingNames != null && data.topThingNames!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('常用事情', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (data.topThingNames ?? '').split(',').take(5).map((name) {
                        return Chip(label: Text(name.trim()));
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // 周趋势
          _WeeklyTrendChart(),
        ],
      ),
    );
  }

  void _showWeeklyView(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('本周概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('本周统计数据展示区域'),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  DailyStatsSnapshot _defaultStats() {
    final now = DateTime.now();
    return DailyStatsSnapshot(
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      createdAt: now,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _MoodEnergyItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _MoodEnergyItem({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _getColor(value)),
        const SizedBox(width: 8),
        Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('$value/5', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getColor(value))),
          ],
        ),
      ],
    );
  }

  Color _getColor(int value) {
    if (value >= 4) return Colors.green;
    if (value >= 3) return Colors.amber;
    return Colors.red;
  }
}

class _WeeklyTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本周趋势', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['一', '二', '三', '四', '五', '六', '日'].map((d) {
                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(child: Icon(Icons.show_chart, color: Colors.white, size: 16)),
                    ),
                    const SizedBox(height: 4),
                    Text(d, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
