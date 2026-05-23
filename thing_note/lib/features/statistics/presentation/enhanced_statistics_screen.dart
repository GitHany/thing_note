import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thing_note/app/theme/app_theme.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/quick_access/presentation/providers/quick_access_provider.dart';
import 'package:thing_note/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class EnhancedStatisticsScreen extends ConsumerStatefulWidget {
  const EnhancedStatisticsScreen({super.key});

  @override
  ConsumerState<EnhancedStatisticsScreen> createState() => _EnhancedStatisticsScreenState();
}

class _EnhancedStatisticsScreenState extends ConsumerState<EnhancedStatisticsScreen> {
  final GlobalKey _statsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsProvider);
    final thingNamesAsync = ref.watch(thingNameListProvider);
    final currentStreakAsync = ref.watch(currentStreakProvider);
    final longestStreakAsync = ref.watch(longestStreakProvider);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final contentPadding = isWideScreen ? 20.0 : 16.0;
    final sectionSpacing = isWideScreen ? 24.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportStatsAsImage(context),
            tooltip: AppLocalizations.of(context)!.exportStats,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _statsKey,
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (stats) {
            final totalCount = stats['totalCount'] as int;
            final weekCount = stats['weekCount'] as int;
            final monthCount = stats['monthlyCount'] as Map<String, int>;
            final thingNameCount = stats['thingNameCount'] as Map<int, int>;
            final totalDuration = stats['totalDuration'] as int? ?? 0;

            final thingNames = thingNamesAsync.valueOrNull ?? [];
            final thingNameMap = {for (final tn in thingNames) if (tn.id != null) tn.id!: tn.name};

            // Calculate most used
            int? mostUsedThingNameId;
            int maxCount = 0;
            thingNameCount.forEach((id, count) {
              if (count > maxCount) {
                maxCount = count;
                mostUsedThingNameId = id;
              }
            });

            final mostUsedThingName = mostUsedThingNameId != null
                ? thingNameMap[mostUsedThingNameId] ?? 'Unknown'
                : null;

            // Calculate average duration
            final avgDuration = totalCount > 0 ? totalDuration ~/ totalCount : 0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak section
                  _buildStreakSection(context, currentStreakAsync, longestStreakAsync),
                  SizedBox(height: sectionSpacing),

                  // Summary cards
                  _buildEnhancedSummaryCards(context, totalCount, weekCount, totalDuration, avgDuration),
                  SizedBox(height: sectionSpacing),

                  // Most used sections
                  if (mostUsedThingName != null) ...[
                    _buildMostUsedSection(context, mostUsedThingName, maxCount),
                    SizedBox(height: sectionSpacing),
                  ],

                  // Duration breakdown
                  _buildDurationSection(context, totalDuration, totalCount),
                  SizedBox(height: sectionSpacing),

                  // Weekly trend
                  _buildWeeklyTrendSection(context, weekCount, monthCount),
                  SizedBox(height: sectionSpacing),

                  // Category distribution
                  if (thingNameCount.isNotEmpty) ...[
                    _buildCategoryDistributionSection(context, thingNameCount, thingNameMap),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStreakSection(
    BuildContext context,
    AsyncValue<int> currentStreakAsync,
    AsyncValue<int> longestStreakAsync,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: EdgeInsets.all(isWideScreen ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.recordStreaks,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  context,
                  title: AppLocalizations.of(context)!.currentStreak,
                  valueAsync: currentStreakAsync,
                  icon: Icons.play_arrow,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStreakCard(
                  context,
                  title: AppLocalizations.of(context)!.longestStreak,
                  valueAsync: longestStreakAsync,
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context, {
    required String title,
    required AsyncValue<int> valueAsync,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          valueAsync.when(
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Icon(Icons.error, size: 22),
            data: (value) => Text(
              AppLocalizations.of(context)!.days(value),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCards(
    BuildContext context,
    int totalCount,
    int weekCount,
    int totalDuration,
    int avgDuration,
  ) {
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: AppLocalizations.of(context)!.totalRecords,
                value: '$totalCount',
                subtitle: AppLocalizations.of(context)!.recordCount(totalCount),
                icon: Icons.note,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                context,
                title: AppLocalizations.of(context)!.thisWeek,
                value: '$weekCount',
                subtitle: AppLocalizations.of(context)!.recordCount(weekCount),
                icon: Icons.calendar_today,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: AppLocalizations.of(context)!.totalDuration,
                value: DurationFormatter.formatShort(Duration(seconds: totalDuration)),
                icon: Icons.timer,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                context,
                title: AppLocalizations.of(context)!.averageDuration,
                value: DurationFormatter.formatShort(Duration(seconds: avgDuration)),
                icon: Icons.av_timer,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMostUsedSection(BuildContext context, String mostUsed, int count) {
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.mostUsedThingName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  mostUsed,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.recordCount(count),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection(BuildContext context, int totalDuration, int totalCount) {
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.totalDuration,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildDurationChip(
                context,
                label: AppLocalizations.of(context)!.hours(totalDuration ~/ 3600),
                icon: Icons.schedule,
              ),
              const SizedBox(width: 10),
              _buildDurationChip(
                context,
                label: AppLocalizations.of(context)!.minutes((totalDuration % 3600) ~/ 60),
                icon: Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(BuildContext context, {required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendSection(
    BuildContext context,
    int weekCount,
    Map<String, int> monthlyCount,
  ) {
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.weeklyTrend,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: _buildSimpleBarChart(context, weekCount),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(BuildContext context, int weekCount) {
    // Simple visual representation
    const maxValue = 20; // Scale for visualization
    final height = (weekCount / maxValue).clamp(0.1, 1.0);

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 70,
              height: 85 * height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$weekCount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          AppLocalizations.of(context)!.records,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCategoryDistributionSection(
    BuildContext context,
    Map<int, int> thingNameCount,
    Map<int, String> thingNameMap,
  ) {
    final sortedEntries = thingNameCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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

    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.thingNameDistribution,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedEntries.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final thingEntry = entry.value;
            final name = thingNameMap[thingEntry.key] ?? 'Unknown';
            final count = thingEntry.value;
            final total = thingNameCount.values.fold(0, (sum, c) => sum + c);
            final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name)),
                  Text(
                    '$count ($percentage%)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _exportStatsAsImage(BuildContext context) async {
    try {
      final boundary = _statsKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Save to temp file
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${appDir.path}/stats_$timestamp.png');
      await file.writeAsBytes(bytes);

      // Share
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: AppLocalizations.of(context)!.exportStats,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.statsExportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.exportFailed(e.toString()))),
        );
      }
    }
  }
}