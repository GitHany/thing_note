import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/activity_correlation_engine/data/activity_correlation_repository.dart';
import 'package:thing_note/features/activity_correlation_engine/domain/activity_correlation.dart';

final activityCorrelationsProvider = FutureProvider<List<ActivityCorrelation>>((ref) async {
  final repository = ref.watch(activityCorrelationRepositoryProvider);
  return repository.getAllCorrelations();
});

final strongCorrelationsProvider = FutureProvider<List<ActivityCorrelation>>((ref) async {
  final repository = ref.watch(activityCorrelationRepositoryProvider);
  return repository.getStrongCorrelations();
});

class ActivityCorrelationEngineScreen extends ConsumerWidget {
  const ActivityCorrelationEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correlationsAsync = ref.watch(activityCorrelationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('活动关联引擎'),
      ),
      body: correlationsAsync.when(
        data: (correlations) {
          if (correlations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  const Text('暂无关联数据'),
                  const SizedBox(height: 8),
                  const Text('使用应用一段时间后，系统会自动分析活动关联'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, correlations),
                const SizedBox(height: 24),
                _buildCorrelationChart(context, correlations),
                const SizedBox(height: 24),
                _buildCorrelationList(context, correlations),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<ActivityCorrelation> correlations) {
    final strongCount = correlations.where((c) => c.correlationScore.abs() > 0.5).length;
    final avgConfidence = correlations.isEmpty
        ? 0.0
        : correlations.map((c) => c.confidenceLevel).reduce((a, b) => a + b) / correlations.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 32),
                  const SizedBox(height: 8),
                  Text('$strongCount', style: Theme.of(context).textTheme.headlineMedium),
                  const Text('强关联'),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.analytics, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text('${avgConfidence.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineMedium),
                  const Text('平均置信度'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationChart(BuildContext context, List<ActivityCorrelation> correlations) {
    final displayCorrelations = correlations.take(6).toList();
    if (displayCorrelations.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('关联强度分布', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  minY: -1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < displayCorrelations.length) {
                            final name = displayCorrelations[value.toInt()].activityName;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.length > 8 ? '${name.substring(0, 8)}...' : name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toString(), style: const TextStyle(fontSize: 10));
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, horizontalInterval: 0.5),
                  barGroups: displayCorrelations.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.correlationScore,
                          color: entry.value.correlationColor,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationList(BuildContext context, List<ActivityCorrelation> correlations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('详细关联', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...correlations.map((c) => _buildCorrelationTile(context, c)),
      ],
    );
  }

  Widget _buildCorrelationTile(BuildContext context, ActivityCorrelation correlation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: correlation.correlationColor.withOpacity( 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${(correlation.correlationScore * 100).toInt()}%',
              style: TextStyle(
                color: correlation.correlationColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(correlation.activityName),
        subtitle: Text('${correlation.resultMetric} · ${correlation.correlationLabel}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('样本 ${correlation.sampleCount}', style: Theme.of(context).textTheme.bodySmall),
            Text('置信度 ${(correlation.confidenceLevel * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}