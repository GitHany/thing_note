import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/time_insight_report/data/time_insight_report_service.dart';
import '../domain/time_insight_report_models.dart';

/// 时间洞察报告屏幕
class TimeInsightReportScreen extends ConsumerStatefulWidget {
  final TimePeriod initialPeriod;

  const TimeInsightReportScreen({
    super.key,
    this.initialPeriod = TimePeriod.thisWeek,
  });

  @override
  ConsumerState<TimeInsightReportScreen> createState() => _TimeInsightReportScreenState();
}

class _TimeInsightReportScreenState extends ConsumerState<TimeInsightReportScreen> {
  TimePeriod _selectedPeriod = TimePeriod.thisWeek;
  TimeInsightReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(timeInsightReportServiceProvider);
      final report = await service.generateReport(_selectedPeriod);

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成报告失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间洞察'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 分享报告
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? _buildEmptyState()
              : _buildReportContent(),
      bottomNavigationBar: _buildPeriodSelector(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '开始记录后，这里会显示您的时间洞察',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          if (_report!.comparison != null) ...[
            _buildComparisonCard(),
            const SizedBox(height: 16),
          ],
          _buildPatternsCard(),
          const SizedBox(height: 16),
          _buildInsightsCard(),
          const SizedBox(height: 16),
          _buildDistributionCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalRecords = _report!.distribution.thingNameDistribution.values.fold(0, (a, b) => a + b);
    final totalMinutes = _report!.distribution.hourDistribution.values.fold(0, (a, b) => a + b);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  '记录数',
                  '$totalRecords',
                  Icons.edit_note,
                ),
                _buildSummaryItem(
                  '总时长',
                  _formatMinutes(totalMinutes),
                  Icons.schedule,
                ),
                _buildSummaryItem(
                  '洞察',
                  '${_report!.insights.length}',
                  Icons.lightbulb,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    final comparison = _report!.comparison!;
    final isPositive = comparison.totalRecordsChange >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '对比上周',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCompareItem(
                    '记录数',
                    '${comparison.totalRecordsChange >= 0 ? '+' : ''}${comparison.totalRecordsChange}',
                    '${comparison.totalRecordsChangePercent.toStringAsFixed(1)}%',
                    isPositive,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompareItem(
                    '时长',
                    '${comparison.totalMinutesChange >= 0 ? '+' : ''}${comparison.totalMinutesChange}分钟',
                    null,
                    comparison.totalMinutesChange >= 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareItem(String label, String value, String? percent, bool isPositive) {
    final color = isPositive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (percent != null)
            Text(
              percent,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatternsCard() {
    if (_report!.patterns.isEmpty) return const SizedBox.shrink();

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
                  '识别模式',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._report!.patterns.map((pattern) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pattern.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(pattern.confidence * 100).toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pattern.description,
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildInsightsCard() {
    if (_report!.insights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '智能洞察',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_report!.insights.map((insight) {
              IconData icon;
              Color color;

              switch (insight.type) {
                case InsightType.highlight:
                  icon = Icons.star;
                  color = Colors.amber;
                  break;
                case InsightType.improvement:
                  icon = Icons.trending_up;
                  color = Colors.blue;
                  break;
                case InsightType.alert:
                  icon = Icons.warning;
                  color = Colors.orange;
                  break;
                case InsightType.achievement:
                  icon = Icons.emoji_events;
                  color = Colors.purple;
                  break;
              }

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(insight.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.description),
                    if (insight.suggestion != null)
                      Text(
                        insight.suggestion!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard() {
    if (_report!.distribution.hourDistribution.isEmpty) return const SizedBox.shrink();

    // 找出最活跃的小时
    final sortedHours = _report!.distribution.hourDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topHours = sortedHours.take(5).toList();
    final maxMinutes = topHours.isNotEmpty ? topHours.first.value : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '时间分布',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: topHours.map((entry) {
                  final height = (entry.value / maxMinutes * 100).toDouble();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height.clamp(10, 100),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_getPeriodLabel(period)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriod = period);
                    _generateReport();
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return '今天';
      case TimePeriod.thisWeek:
        return '本周';
      case TimePeriod.thisMonth:
        return '本月';
      case TimePeriod.thisYear:
        return '今年';
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h${mins > 0 ? "${mins}m" : ""}';
  }
}