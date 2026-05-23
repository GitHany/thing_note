import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/daily_progress_snapshot/data/daily_progress_repository.dart';

final todaySnapshotProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(dailyProgressRepositoryProvider);
  return repository.getTodaySnapshot();
});

class DailyProgressSnapshotScreen extends ConsumerWidget {
  const DailyProgressSnapshotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(todaySnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日进度快照'),
      ),
      body: snapshotAsync.when(
        data: (snapshot) => _buildSnapshot(context, snapshot),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildSnapshot(BuildContext context, Map<String, dynamic> snapshot) {
    final completed = snapshot['completed_items'] as int? ?? 0;
    final total = snapshot['total_items'] as int? ?? 0;
    final progress = total > 0 ? completed / total : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context),
          const SizedBox(height: 24),
          _buildProgressRing(context, completed, total, progress),
          const SizedBox(height: 24),
          _buildStatsGrid(context, snapshot),
          const SizedBox(height: 24),
          _buildWeeklyComparison(context),
          const SizedBox(height: 24),
          _buildHighlights(context, snapshot),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${now.day}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '今日进度快照',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRing(BuildContext context, int completed, int total, double progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 45,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: progress * 100,
                          color: Theme.of(context).colorScheme.primary,
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (1 - progress) * 100,
                          color: Theme.of(context).disabledColor.withOpacity( 0.3),
                          radius: 20,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('完成率', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressRow(context, '已完成', completed, Colors.green),
                  const SizedBox(height: 8),
                  _buildProgressRow(context, '进行中', total - completed, Colors.orange),
                  const SizedBox(height: 8),
                  _buildProgressRow(context, '总计', total, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text('$count 项', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> snapshot) {
    final records = snapshot['record_count'] as int? ?? 0;
    final habits = snapshot['habit_completion'] as int? ?? 0;
    final goals = snapshot['goal_progress'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('今日统计', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, '📝', '记录数', '$records')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, '✅', '习惯完成', '$habits')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, '🎯', '目标进度', '$goals%')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String emoji, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyComparison(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('本周对比', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildComparisonItem(context, '昨天', '+5%', true),
                _buildComparisonItem(context, '上周同期', '-2%', false),
                _buildComparisonItem(context, '本周平均', '+8%', true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(BuildContext context, String label, String change, bool isPositive) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          change,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights(BuildContext context, Map<String, dynamic> snapshot) {
    final highlights = snapshot['highlights'] as List<String>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('今日亮点', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (highlights.isEmpty)
              const Text('暂无亮点记录')
            else
              ...highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('• '),
                    Expanded(child: Text(h)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}