import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/focus_session_analytics/data/focus_session_analytics_repository.dart';

final analyticsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(focusSessionAnalyticsProvider);
  return repository.getAnalyticsSummary();
});

final efficiencyTrendProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(focusSessionAnalyticsProvider);
  return repository.getEfficiencyTrend();
});

final distractionBreakdownProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(focusSessionAnalyticsProvider);
  return repository.getDistractionBreakdown();
});

class FocusSessionAnalyticsScreen extends ConsumerWidget {
  const FocusSessionAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注会话分析'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(context, ref),
            const SizedBox(height: 24),
            _buildEfficiencyTrendChart(context, ref),
            const SizedBox(height: 24),
            _buildDistractionAnalysis(context, ref),
            const SizedBox(height: 24),
            _buildSuggestionsCard(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return summaryAsync.when(
      data: (summary) => Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              '总专注次数',
              '${summary['total_sessions']}',
              Icons.timer,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              context,
              '平均效率',
              '${((summary['avg_efficiency'] as double?) ?? 0).toStringAsFixed(1)}%',
              Icons.speed,
              Colors.green,
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('加载失败: $e'),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyTrendChart(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(efficiencyTrendProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('效率趋势', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: trendAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text('暂无数据'));
                  }
                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), (e.value['avg_efficiency'] as double?) ?? 0);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity( 0.2)),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistractionAnalysis(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(distractionBreakdownProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('分心模式分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            breakdownAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Text('暂无分心数据');
                }
                return Column(
                  children: data.entries.map((entry) {
                    final total = data.values.reduce((a, b) => a + b);
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Expanded(
                            flex: 2,
                            child: LinearProgressIndicator(
                              value: entry.value / total,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$percentage%'),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('加载失败: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        final bestPeriod = summary['best_period'] as String?;
        final suggestions = <String>[];

        if (bestPeriod != null) {
          suggestions.add('你的最佳专注时段是 $bestPeriod，建议在该时段安排重要任务');
        }

        final avgEfficiency = (summary['avg_efficiency'] as double?) ?? 0;
        if (avgEfficiency < 70) {
          suggestions.add('效率有提升空间，尝试使用番茄工作法（25分钟专注+5分钟休息）');
        }

        if (suggestions.isEmpty) {
          suggestions.add('继续保持当前的专注习惯，你的专注力表现良好！');
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text('个性化建议', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(s)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}