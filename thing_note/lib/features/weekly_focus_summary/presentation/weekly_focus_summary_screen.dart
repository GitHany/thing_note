import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Weekly Focus AI Summary Provider
final weeklyFocusSummaryProvider = FutureProvider<WeeklyFocusSummary>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final weekRecords = records.where((r) {
    return r.occurredAt.isAfter(weekStart) && r.occurredAt.isBefore(weekEnd);
  }).toList();

  // Analyze patterns
  final topTags = _extractTopTags(weekRecords);
  final dailyDistribution = _calculateDailyDistribution(weekRecords);
  final moodTrend = _calculateMoodTrend(weekRecords);
  final insights = _generateInsights(weekRecords);

  return WeeklyFocusSummary(
    weekStart: weekStart,
    weekEnd: weekEnd,
    totalRecords: weekRecords.length,
    topTags: topTags,
    dailyDistribution: dailyDistribution,
    moodTrend: moodTrend,
    insights: insights,
    highlights: _generateHighlights(weekRecords),
  );
});

List<String> _extractTopTags(List<EpisodeRecord> records) {
  final tags = <String, int>{};
  for (final record in records) {
    final matches = RegExp(r'#(\w+)').allMatches(record.note);
    for (final match in matches) {
      final tag = match.group(1)!;
      tags[tag] = (tags[tag] ?? 0) + 1;
    }
  }
final sortedEntries = tags.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sortedEntries.take(5).map((e) => e.key).toList();
}

Map<int, int> _calculateDailyDistribution(List<EpisodeRecord> records) {
  final distribution = <int, int>{};
  for (int i = 0; i < 7; i++) {
    distribution[i] = 0;
  }
  for (final record in records) {
    final dayIndex = record.occurredAt.weekday - 1;
    distribution[dayIndex] = (distribution[dayIndex] ?? 0) + 1;
  }
  return distribution;
}

Map<String, double> _calculateMoodTrend(List<EpisodeRecord> records) {
  // Simplified mood calculation based on note length
  final moodByDay = <String, double>{};
  for (final record in records) {
    final dateKey = DateFormat('yyyy-MM-dd').format(record.occurredAt);
    final noteLength = record.note.length;
    if (noteLength > 50) {
      moodByDay[dateKey] = (moodByDay[dateKey] ?? 0) + 1;
    }
  }
  return moodByDay;
}

List<String> _generateInsights(List<EpisodeRecord> records) {
  final insights = <String>[];
  
  if (records.isEmpty) {
    insights.add('本周暂无记录，建议开始记录生活点滴');
    return insights;
  }

  final totalRecords = records.length;
  final avgPerDay = (totalRecords / 7).toStringAsFixed(1);
  insights.add('本周共记录 $totalRecords 条，平均每天 $avgPerDay 条');

  // Time patterns
  final morningRecords = records.where((r) => r.occurredAt.hour < 12).length;
  final afternoonRecords = records.where((r) => r.occurredAt.hour >= 12 && r.occurredAt.hour < 18).length;
  final eveningRecords = records.where((r) => r.occurredAt.hour >= 18).length;

  if (morningRecords > afternoonRecords && morningRecords > eveningRecords) {
    insights.add('你是个早起的人！上午记录最多($morningRecords条)，精力充沛');
  } else if (eveningRecords > morningRecords) {
    insights.add('你是夜猫子型！晚上记录最多($eveningRecords条)，善于反思');
  }

  // Photo usage
  final photoRecords = records.where((r) => r.hasPhotos).length;
  if (photoRecords > totalRecords * 0.3) {
    insights.add('你喜欢用照片记录生活！$photoRecords 条记录包含照片');
  }

  // Favorite records
  final favoriteRecords = records.where((r) => r.isFavorite).length;
  if (favoriteRecords > 0) {
    insights.add('$favoriteRecords 条记录被标记为收藏，这些对你很重要');
  }

  return insights;
}

List<String> _generateHighlights(List<EpisodeRecord> records) {
  if (records.isEmpty) return [];

  final highlights = <String>[];

  // Longest note
  records.sort((a, b) => b.note.length.compareTo(a.note.length));
  if (records.first.note.length > 100) {
    highlights.add('最详细的记录：${records.first.note.substring(0, 50)}...');
  }

  // Most media
  records.sort((a, b) => (b.photoPaths.length + b.audioPaths.length + b.videoPaths.length)
      .compareTo(a.photoPaths.length + a.audioPaths.length + a.videoPaths.length));
  if (records.first.photoPaths.isNotEmpty) {
    highlights.add('多媒体达人：某条记录包含${records.first.photoPaths.length}张照片');
  }

  return highlights;
}

class WeeklyFocusSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalRecords;
  final List<String> topTags;
  final Map<int, int> dailyDistribution;
  final Map<String, double> moodTrend;
  final List<String> insights;
  final List<String> highlights;

  WeeklyFocusSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalRecords,
    required this.topTags,
    required this.dailyDistribution,
    required this.moodTrend,
    required this.insights,
    required this.highlights,
  });
}

class WeeklyFocusAISummaryScreen extends ConsumerWidget {
  const WeeklyFocusAISummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklyFocusSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每周专注AI总结'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSummary(context),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (summary) => _buildContent(context, ref, summary),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WeeklyFocusSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekHeader(context, summary),
          const SizedBox(height: 16),
          _buildOverviewCard(context, summary),
          const SizedBox(height: 16),
          _buildDailyChart(context, summary),
          const SizedBox(height: 16),
          _buildInsightsCard(context, summary),
          const SizedBox(height: 16),
          if (summary.highlights.isNotEmpty) ...[
            _buildHighlightsCard(context, summary),
            const SizedBox(height: 16),
          ],
          if (summary.topTags.isNotEmpty) ...[
            _buildTagsCard(context, summary),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context, WeeklyFocusSummary summary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${DateFormat('MM/dd').format(summary.weekStart)} - ${DateFormat('MM/dd').format(summary.weekEnd)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            // Previous week
          },
        ),
        TextButton(
          onPressed: () {
            // Go to current week
          },
          child: const Text('本周'),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // Next week
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, WeeklyFocusSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    context,
                    '总记录',
                    summary.totalRecords.toString(),
                    Icons.note,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    context,
                    '日均',
                    (summary.totalRecords / 7).toStringAsFixed(1),
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    context,
                    '标签',
                    summary.topTags.length.toString(),
                    Icons.tag,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart(BuildContext context, WeeklyFocusSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '每日分布',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: summary.dailyDistribution.values.reduce((a, b) => a > b ? a : b).toDouble() + 5,
                  barGroups: summary.dailyDistribution.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['一', '二', '三', '四', '五', '六', '日'];
                          if (value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, WeeklyFocusSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 分析',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...summary.insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsCard(BuildContext context, WeeklyFocusSummary summary) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '本周亮点',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...summary.highlights.map((highlight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(highlight),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context, WeeklyFocusSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '热门标签',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.topTags.map((tag) {
                return Chip(
                  avatar: const Icon(Icons.tag, size: 16),
                  label: Text('#$tag'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _shareSummary(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }
}
