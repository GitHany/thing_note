import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class AdvancedAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  ConsumerState<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState
    extends ConsumerState<AdvancedAnalyticsScreen> {
  String _selectedPeriod = 'week';

  final List<_Insight> _insights = [
    _Insight(
      icon: Icons.trending_up,
      title: '生产力提升',
      description: '您的记录数量比上周增加了 23%',
      color: Colors.green,
    ),
    _Insight(
      icon: Icons.schedule,
      title: '最佳时间',
      description: '您倾向于在上午 9-11 点记录事件',
      color: Colors.blue,
    ),
    _Insight(
      icon: Icons.category,
      title: '高频分类',
      description: '"工作"类别占比最高 (45%)',
      color: Colors.orange,
    ),
    _Insight(
      icon: Icons.insights,
      title: '趋势发现',
      description: '周末记录数量呈下降趋势',
      color: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.advancedAnalytics),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Period selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PeriodChip(
                    label: '日',
                    isSelected: _selectedPeriod == 'day',
                    onTap: () => setState(() => _selectedPeriod = 'day'),
                  ),
                  _PeriodChip(
                    label: '周',
                    isSelected: _selectedPeriod == 'week',
                    onTap: () => setState(() => _selectedPeriod = 'week'),
                  ),
                  _PeriodChip(
                    label: '月',
                    isSelected: _selectedPeriod == 'month',
                    onTap: () => setState(() => _selectedPeriod = 'month'),
                  ),
                  _PeriodChip(
                    label: '年',
                    isSelected: _selectedPeriod == 'year',
                    onTap: () => setState(() => _selectedPeriod = 'year'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI Insights
          Text(
            AppLocalizations.of(context)!.aiInsights,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...(_insights.map((insight) => _buildInsightCard(insight))),
          const SizedBox(height: 24),

          // Activity chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.activityTrend,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _getPeriodLabel(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 30,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final days = ['一', '二', '三', '四', '五', '六', '日'];
                                return Text(
                                  days[value.toInt()],
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.categoryDistribution,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: 45,
                                  title: '45%',
                                  color: Colors.blue,
                                ),
                                PieChartSectionData(
                                  value: 30,
                                  title: '30%',
                                  color: Colors.green,
                                ),
                                PieChartSectionData(
                                  value: 25,
                                  title: '25%',
                                  color: Colors.orange,
                                ),
                              ],
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegendItem(color: Colors.blue, label: '工作'),
                            SizedBox(height: 8),
                            _LegendItem(color: Colors.green, label: '生活'),
                            SizedBox(height: 8),
                            _LegendItem(color: Colors.orange, label: '学习'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prediction
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.prediction,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.event_note),
                    title: const Text('下周预计记录数'),
                    trailing: Text(
                      '~145',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('最佳记录日'),
                    trailing: Text(
                      '周三',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (index) {
      final values = [15, 22, 18, 25, 20, 8, 5];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index].toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildInsightCard(_Insight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: insight.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(insight.icon, color: insight.color),
        ),
        title: Text(insight.title),
        subtitle: Text(insight.description),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'day':
        return '今日';
      case 'week':
        return '本周';
      case 'month':
        return '本月';
      case 'year':
        return '本年';
      default:
        return '';
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('报告导出中...')),
    );
  }
}

class _Insight {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _Insight({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}