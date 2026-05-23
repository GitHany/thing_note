import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);
    final thingNamesAsync = ref.watch(thingNameListProvider);
    
    // Responsive layout based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocalizations.of(context)!.exportStatistics,
            onPressed: () => _exportStatistics(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.refresh,
            onPressed: () => ref.invalidate(statisticsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (stats) {
          final totalCount = stats['totalCount'] as int;
          final weekCount = stats['weekCount'] as int;
          final photoCount = stats['photoCount'] as int;
          final audioCount = stats['audioCount'] as int;
          final videoCount = stats['videoCount'] as int;
          final favoriteCount = stats['favoriteCount'] as int;
          final monthlyCount = stats['monthlyCount'] as Map<String, int>;
          final thingNameCount = stats['thingNameCount'] as Map<int, int>;

          final thingNames = thingNamesAsync.valueOrNull ?? [];
          final thingNameMap = {for (final tn in thingNames) if (tn.id != null) tn.id!: tn.name};

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards - responsive grid
                if (isWideScreen)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.totalRecords, value: '$totalCount', icon: Icons.note, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.thisWeek, value: '$weekCount', icon: Icons.calendar_today, color: Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.favorites, value: '$favoriteCount', icon: Icons.star, color: Colors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.media, value: '${photoCount + audioCount + videoCount}', icon: Icons.photo_library, color: Colors.purple)),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.totalRecords, value: '$totalCount', icon: Icons.note, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.thisWeek, value: '$weekCount', icon: Icons.calendar_today, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.favorites, value: '$favoriteCount', icon: Icons.star, color: Colors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, title: AppLocalizations.of(context)!.media, value: '${photoCount + audioCount + videoCount}', icon: Icons.photo_library, color: Colors.purple)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Media breakdown
                Text(
                  AppLocalizations.of(context)!.mediaBreakdown,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (isWideScreen)
                  Row(
                    children: [
                      Expanded(child: _buildMediaChip(context, '$photoCount', AppLocalizations.of(context)!.photos, Icons.photo, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMediaChip(context, '$audioCount', AppLocalizations.of(context)!.audio, Icons.mic, Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMediaChip(context, '$videoCount', AppLocalizations.of(context)!.videos, Icons.videocam, Colors.red)),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: _buildMediaChip(context, '$photoCount', AppLocalizations.of(context)!.photos, Icons.photo, Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMediaChip(context, '$audioCount', AppLocalizations.of(context)!.audio, Icons.mic, Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMediaChip(context, '$videoCount', AppLocalizations.of(context)!.videos, Icons.videocam, Colors.red)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Trend chart
                Text(
                  AppLocalizations.of(context)!.recordTrend,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive chart width based on container
                      return monthlyCount.isEmpty
                          ? Center(child: Text(AppLocalizations.of(context)!.noData))
                          : _buildTrendChart(context, monthlyCount);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Bar chart - Weekly distribution
                if (monthlyCount.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.weeklyDistribution,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _buildBarChart(context, monthlyCount),
                  ),
                  const SizedBox(height: 24),
                ],

                // Category distribution
                if (thingNameCount.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.categoryDistribution,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: _buildPieChart(context, thingNameCount, thingNameMap),
                  ),
                  const SizedBox(height: 24),

                  // Category list with details
                  _buildCategoryDetails(context, thingNameCount, thingNameMap),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaChip(
    BuildContext context,
    String count,
    String label,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              count,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, Map<String, int> monthlyData) {
    final sortedKeys = monthlyData.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox();

    final spots = <FlSpot>[];
    for (var i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[sortedKeys[i]]!.toDouble()));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedKeys.length && index % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedKeys[index].substring(5), // MM
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY > 0 ? maxY / 4 : 1,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, Map<String, int> monthlyData) {
    final sortedKeys = monthlyData.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox();

    final recentMonths = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;
    final maxY = recentMonths.map((k) => monthlyData[k]!).fold(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY.toDouble() * 1.2 : 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 2.5,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < recentMonths.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      recentMonths[index].substring(5),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY > 0 ? maxY / 4 : 2.5,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(recentMonths.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[recentMonths[index]]!.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<int, int> thingNameCount,
    Map<int, String> thingNameMap,
  ) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final sections = <PieChartSectionData>[];
    final total = thingNameCount.values.fold(0, (sum, count) => sum + count);

    var colorIndex = 0;
    for (final entry in thingNameCount.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: '$percentage%',
          color: colors[colorIndex % colors.length],
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: thingNameCount.entries.take(5).toList().asMap().entries.map((e) {
              final name = thingNameMap[e.value.key] ?? 'Unknown';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value.value}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDetails(
    BuildContext context,
    Map<int, int> thingNameCount,
    Map<int, String> thingNameMap,
  ) {
    final sortedEntries = thingNameCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分类详情',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...sortedEntries.take(8).map((entry) {
              final name = thingNameMap[entry.key] ?? 'Unknown';
              final percentage = (entry.value / thingNameCount.values.fold(0, (a, b) => a + b) * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${entry.value}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        textAlign: TextAlign.end,
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

  Future<void> _exportStatistics(BuildContext context, WidgetRef ref) async {
    try {
      final stats = await ref.read(statisticsProvider.future);
      final thingNames = ref.read(thingNameListProvider).valueOrNull ?? [];

      final buffer = StringBuffer();
      buffer.writeln('=== 事件记录统计报告 ===');
      buffer.writeln('生成时间: ${DateTime.now().toString()}');
      buffer.writeln('');

      buffer.writeln('--- 概览 ---');
      buffer.writeln('总记录数: ${stats['totalCount']}');
      buffer.writeln('本周记录: ${stats['weekCount']}');
      buffer.writeln('收藏数: ${stats['favoriteCount']}');
      buffer.writeln('媒体总数: ${(stats['photoCount'] as int) + (stats['audioCount'] as int) + (stats['videoCount'] as int)}');
      buffer.writeln('');

      buffer.writeln('--- 媒体分布 ---');
      buffer.writeln('照片: ${stats['photoCount']}');
      buffer.writeln('音频: ${stats['audioCount']}');
      buffer.writeln('视频: ${stats['videoCount']}');
      buffer.writeln('');

      final thingNameCount = stats['thingNameCount'] as Map<int, int>;
      if (thingNameCount.isNotEmpty) {
        buffer.writeln('--- 分类统计 ---');
        final thingNameMap = {for (final tn in thingNames) if (tn.id != null) tn.id!: tn.name};
        final sorted = thingNameCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final entry in sorted) {
          final name = thingNameMap[entry.key] ?? 'Unknown';
          buffer.writeln('$name: ${entry.value}');
        }
      }

      // Show result
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('统计报告'),
            content: SingleChildScrollView(
              child: SelectableText(
                buffer.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }
}