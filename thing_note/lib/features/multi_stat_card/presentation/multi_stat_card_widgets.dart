import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/multi_stat_card/domain/multi_stat_card_models.dart';

/// 多维度统计卡片组件
class MultiStatCard extends StatelessWidget {
  final StatData data;
  final CardLayout layout;
  final VoidCallback? onTap;

  const MultiStatCard({
    super.key,
    required this.data,
    this.layout = CardLayout.standard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (layout) {
      case CardLayout.compact:
        return _buildCompactLayout(context);
      case CardLayout.standard:
        return _buildStandardLayout(context);
      case CardLayout.expanded:
        return _buildExpandedLayout(context);
      case CardLayout.chart:
        return _buildChartLayout(context);
    }
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getStatIcon(data.type),
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatTitle(data.type),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _formatValue(data.value),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (data.changePercent != 0) _buildTrendIndicator(context),
      ],
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatIcon(data.type),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _getStatTitle(data.type),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _formatValue(data.value),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (data.changePercent != 0) ...[
          const SizedBox(height: 8),
          _buildTrendIndicator(context),
        ],
      ],
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatIcon(data.type),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _getStatTitle(data.type),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (data.previousValue != null)
              Text(
                '上期: ${_formatValue(data.previousValue)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _formatValue(data.value),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (data.changePercent != 0) ...[
          const SizedBox(height: 8),
          _buildTrendIndicator(context),
        ],
        if (data.trend.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMiniChart(context),
        ],
      ],
    );
  }

  Widget _buildChartLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatIcon(data.type),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _getStatTitle(data.type),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: _buildLineChart(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _formatValue(data.value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    final isPositive = data.changePercent > 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${data.changePercent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(BuildContext context) {
    if (data.trend.length < 2) return const SizedBox.shrink();

    final spots = data.trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return SizedBox(
      height: 40,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    if (data.trend.length < 2) {
      return const Center(child: Text('数据不足'));
    }

    final spots = data.trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final maxY = data.trend.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatIcon(StatType type) {
    switch (type) {
      case StatType.recordCount:
        return Icons.edit_note;
      case StatType.totalDuration:
        return Icons.schedule;
      case StatType.activeDays:
        return Icons.calendar_today;
      case StatType.topThing:
        return Icons.category;
      case StatType.topTag:
        return Icons.label;
      case StatType.moodAverage:
        return Icons.mood;
      case StatType.streakDays:
        return Icons.local_fire_department;
      case StatType.completionRate:
        return Icons.check_circle;
    }
  }

  String _getStatTitle(StatType type) {
    switch (type) {
      case StatType.recordCount:
        return '记录数';
      case StatType.totalDuration:
        return '总时长';
      case StatType.activeDays:
        return '活跃天数';
      case StatType.topThing:
        return '最常用事情';
      case StatType.topTag:
        return '最常用标签';
      case StatType.moodAverage:
        return '平均情绪';
      case StatType.streakDays:
        return '连续天数';
      case StatType.completionRate:
        return '完成率';
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(1);
    return value.toString();
  }
}

/// 统计卡片网格
class StatCardGrid extends StatelessWidget {
  final List<StatData> stats;
  final CardLayout layout;
  final void Function(StatData)? onCardTap;

  const StatCardGrid({
    super.key,
    required this.stats,
    this.layout = CardLayout.compact,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout == CardLayout.compact ? 2 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: layout == CardLayout.compact ? 1.5 : 2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return MultiStatCard(
          data: stats[index],
          layout: layout,
          onTap: () => onCardTap?.call(stats[index]),
        );
      },
    );
  }
}