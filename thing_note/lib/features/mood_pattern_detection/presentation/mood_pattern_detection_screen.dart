import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/mood_pattern_detection/data/mood_pattern_repository.dart';
import 'package:thing_note/features/mood_pattern_detection/domain/mood_pattern.dart';

final moodPatternsProvider = FutureProvider<List<MoodPattern>>((ref) async {
  final repository = ref.watch(moodPatternRepositoryProvider);
  return repository.getAllPatterns();
});

final moodTrendProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(moodPatternRepositoryProvider);
  return repository.getMoodTrend(days: 30);
});

class MoodPatternDetectionScreen extends ConsumerWidget {
  const MoodPatternDetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(moodPatternsProvider);
    final trendAsync = ref.watch(moodTrendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪模式检测'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodTrendChart(context, trendAsync),
            const SizedBox(height: 24),
            _buildPatternList(context, patternsAsync),
            const SizedBox(height: 24),
            _buildTriggerAnalysis(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTrendChart(BuildContext context, AsyncValue<List<Map<String, dynamic>>> trendAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('30天情绪趋势', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      minY: 1,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              (e.value['mood_score'] as num?)?.toDouble() ?? 3,
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purple.withOpacity( 0.2),
                          ),
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

  Widget _buildPatternList(BuildContext context, AsyncValue<List<MoodPattern>> patternsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('检测到的模式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        patternsAsync.when(
          data: (patterns) {
            if (patterns.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无检测到模式'),
                ),
              );
            }
            return Column(
              children: patterns.map((p) => _buildPatternCard(context, p)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }

  Widget _buildPatternCard(BuildContext context, MoodPattern pattern) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: pattern.patternColor.withOpacity( 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(pattern.patternIcon, color: pattern.patternColor),
        ),
        title: Text(_getPatternTitle(pattern.patternType)),
        subtitle: Text('置信度: ${(pattern.confidenceScore * 100).toInt()}% · ${pattern.occurrenceCount}次'),
        trailing: Chip(
          label: Text(pattern.patternType),
          backgroundColor: pattern.patternColor.withOpacity( 0.1),
        ),
      ),
    );
  }

  String _getPatternTitle(String type) {
    switch (type) {
      case 'positive':
        return '积极情绪周期';
      case 'negative':
        return '低落情绪预警';
      case 'cyclical':
        return '周期性情绪波动';
      case 'triggered':
        return '触发性情绪变化';
      default:
        return '一般模式';
    }
  }

  Widget _buildTriggerAnalysis(BuildContext context) {
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
                const Text('触发因素分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTriggerItem(context, '工作压力', '75%'),
            _buildTriggerItem(context, '睡眠质量', '60%'),
            _buildTriggerItem(context, '社交活动', '45%'),
            _buildTriggerItem(context, '天气变化', '30%'),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerItem(BuildContext context, String trigger, String impact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(trigger)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: double.parse(impact.replaceAll('%', '')) / 100,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 8),
          Text(impact, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}