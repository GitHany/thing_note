import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/mood_activity_correlation/data/mood_activity_service.dart';
import 'package:thing_note/features/mood_activity_correlation/domain/mood_activity_models.dart';

class MoodActivityCorrelationScreen extends ConsumerStatefulWidget {
  const MoodActivityCorrelationScreen({super.key});

  @override
  ConsumerState<MoodActivityCorrelationScreen> createState() => _MoodActivityCorrelationScreenState();
}

class _MoodActivityCorrelationScreenState extends ConsumerState<MoodActivityCorrelationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪活动关联'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(moodActivityServiceProvider).calculateCorrelations();
              ref.invalidate(correlationResultsProvider);
            },
            tooltip: '重新分析',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: '关联分析'),
            Tab(text: '洞察'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _CorrelationTab(),
          _InsightsTab(),
        ],
      ),
    );
  }
}

/// 概览标签页
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correlationsAsync = ref.watch(correlationResultsProvider);

    return correlationsAsync.when(
      data: (correlations) {
        if (correlations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无足够数据进行分析'),
                SizedBox(height: 8),
                Text(
                  '请继续记录活动和情绪数据',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final positiveCount = correlations.where((c) => c.avgMoodScore > 3.5).length;
        final negativeCount = correlations.where((c) => c.avgMoodScore < 2.5).length;
        final neutralCount = correlations.length - positiveCount - negativeCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 情绪分布卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '活动情绪分布',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.sentiment_satisfied,
                              label: '高情绪',
                              value: '$positiveCount',
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.sentiment_neutral,
                              label: '中性',
                              value: '$neutralCount',
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.sentiment_dissatisfied,
                              label: '低情绪',
                              value: '$negativeCount',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 正面触发因素
              if (correlations.any((c) => c.avgMoodScore > 3.5)) ...[
                const Text(
                  '💡 正面触发因素',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...correlations
                    .where((c) => c.avgMoodScore > 3.5)
                    .take(5)
                    .map((c) => _CorrelationCard(
                          correlation: c,
                          isPositive: true,
                        )),
                const SizedBox(height: 16),
              ],
              // 负面触发因素
              if (correlations.any((c) => c.avgMoodScore < 2.5)) ...[
                const Text(
                  '⚠️ 需注意的活动',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...correlations
                    .where((c) => c.avgMoodScore < 2.5)
                    .take(3)
                    .map((c) => _CorrelationCard(
                          correlation: c,
                          isPositive: false,
                        )),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 关联分析标签页
class _CorrelationTab extends ConsumerWidget {
  const _CorrelationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(moodMatrixProvider);

    return matrixAsync.when(
      data: (matrix) {
        if (matrix == null) {
          return const Center(child: Text('暂无矩阵数据'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '情绪-活动矩阵',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '颜色越深表示该活动在此精力下情绪越好',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // 矩阵可视化
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 表头
                      Row(
                        children: [
                          const SizedBox(width: 80),
                          ...matrix.energyLevels.map((level) => Expanded(
                            child: Text(
                              '$level级',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 数据行
                      ...matrix.activities.take(10).map((activity) {
                        final rowIndex = matrix.activities.indexOf(activity);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  activity.length > 8
                                      ? '${activity.substring(0, 8)}...'
                                      : activity,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              ...matrix.energyLevels.map((level) {
                                final value = matrix.getValue(rowIndex, matrix.energyLevels.indexOf(level));
                                return Expanded(
                                  child: Container(
                                    height: 30,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: _getColorForValue(value),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        value > 0 ? value.toStringAsFixed(1) : '-',
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 图表
              const Text(
                '相关性强度分布',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: matrix.activities.asMap().entries.take(10).map((entry) {
                      final correlation = matrix.correlationMatrix[entry.key];
                      final avgCorrelation = correlation.isEmpty ? 0.0 : correlation.reduce((a, b) => a + b) / correlation.length;
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: avgCorrelation,
                            color: _getColorForValue(avgCorrelation),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < matrix.activities.length) {
                              final name = matrix.activities[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  name.length > 4 ? '${name.substring(0, 4)}...' : name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  Color _getColorForValue(double value) {
    if (value <= 0) return Colors.grey[300]!;
    if (value <= 1.5) return Colors.red[400]!;
    if (value <= 2.5) return Colors.orange[400]!;
    if (value <= 3.5) return Colors.yellow[600]!;
    if (value <= 4.5) return Colors.lightGreen[400]!;
    return Colors.green[600]!;
  }
}

/// 洞察标签页
class _InsightsTab extends ConsumerWidget {
  const _InsightsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(activityInsightsProvider);

    return insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无洞察'),
                SizedBox(height: 8),
                Text(
                  '记录更多数据以获得个性化洞察',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final insight = insights[index];
            return _InsightCard(insight: insight);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 统计卡片
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 关联卡片
class _CorrelationCard extends StatelessWidget {
  final MoodActivityCorrelation correlation;
  final bool isPositive;

  const _CorrelationCard({
    required this.correlation,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
          child: Text(
            correlation.moodEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(correlation.activityName),
        subtitle: Text('基于 ${correlation.sampleCount} 次记录'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              correlation.avgMoodScore.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const Text('/5', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// 洞察卡片
class _InsightCard extends StatelessWidget {
  final ActivityInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final borderColor = insight.insightType == 'positive_trigger'
        ? Colors.green
        : insight.insightType == 'negative_trigger'
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  insight.insightIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (insight.description != null) ...[
              const SizedBox(height: 8),
              Text(
                insight.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '置信度: ${(insight.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}