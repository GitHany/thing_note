import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/smart_time_tracking/data/time_tracking_service.dart';

class SmartTimeTrackingScreen extends ConsumerStatefulWidget {
  const SmartTimeTrackingScreen({super.key});

  @override
  ConsumerState<SmartTimeTrackingScreen> createState() => _SmartTimeTrackingScreenState();
}

class _SmartTimeTrackingScreenState extends ConsumerState<SmartTimeTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('智能时间追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(timeTrackingStatsProvider),
            tooltip: '刷新数据',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: '趋势'),
            Tab(text: '分布'),
            Tab(text: '活动'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _TrendTab(),
          _DistributionTab(),
          _ActivitiesTab(),
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
    final statsAsync = ref.watch(timeTrackingStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总览卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本周时间统计',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.timer,
                            label: '总时长',
                            value: stats.formattedDuration,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.category,
                            label: '活动数',
                            value: '${stats.activityCount}',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.assessment,
                            label: '效率评分',
                            value: stats.formattedEfficiency,
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.event,
                            label: '记录数',
                            value: '${stats.recordCount}',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 效率建议
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          '智能建议',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestion(stats),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Top 活动预览
            if (stats.topActivities.isNotEmpty) ...[
              const Text(
                'Top 活动',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.topActivities.take(5).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = stats.topActivities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(activity.name),
                      trailing: Text(
                        activity.formattedDuration,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  Widget _buildSuggestion(TimeTrackingStats stats) {
    if (stats.efficiencyScore >= 80) {
      return const Text('你的时间管理非常高效！继续保持。');
    } else if (stats.activityCount < 3) {
      return const Text('建议增加活动的多样性，尝试在不同领域投入时间。');
    } else if (stats.totalMinutes < 60) {
      return const Text('记录时间较少，建议更详细地追踪你的时间使用。');
    }
    return const Text('继续保持良好的时间记录习惯。');
  }
}

/// 趋势标签页
class _TrendTab extends ConsumerWidget {
  const _TrendTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(smartTimeTrackingServiceProvider);

    return FutureBuilder<List<DailyTimeTrend>>(
      future: service.getDailyTrend(days: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('暂无数据'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '每日时间趋势',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    barGroups: data.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.totalMinutes.toDouble(),
                            color: Colors.blue,
                            width: 8,
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
                            if (index >= 0 && index < data.length) {
                              final date = data[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${date.month}/${date.day}',
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
              const SizedBox(height: 16),
              // 数据表格
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[data.length - 1 - index];
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('${item.date.month}/${item.date.day}'),
                      trailing: Text(
                        item.formattedDuration,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 分布标签页
class _DistributionTab extends ConsumerWidget {
  const _DistributionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(periodDistributionProvider);

    return distributionAsync.when(
      data: (distribution) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '时间段分布',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (distribution.total == 0)
              const Center(child: Text('暂无数据'))
            else ...[
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (distribution.morning > 0)
                        PieChartSectionData(
                          value: distribution.morning.toDouble(),
                          title: '上午',
                          color: Colors.amber,
                          radius: 80,
                        ),
                      if (distribution.afternoon > 0)
                        PieChartSectionData(
                          value: distribution.afternoon.toDouble(),
                          title: '下午',
                          color: Colors.blue,
                          radius: 80,
                        ),
                      if (distribution.evening > 0)
                        PieChartSectionData(
                          value: distribution.evening.toDouble(),
                          title: '傍晚',
                          color: Colors.orange,
                          radius: 80,
                        ),
                      if (distribution.night > 0)
                        PieChartSectionData(
                          value: distribution.night.toDouble(),
                          title: '夜间',
                          color: Colors.purple,
                          radius: 80,
                        ),
                    ],
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 详细数据
              Card(
                child: Column(
                  children: [
                    _PeriodTile(
                      period: '上午 (06:00-12:00)',
                      minutes: distribution.morning,
                      color: Colors.amber,
                    ),
                    const Divider(height: 1),
                    _PeriodTile(
                      period: '下午 (12:00-18:00)',
                      minutes: distribution.afternoon,
                      color: Colors.blue,
                    ),
                    const Divider(height: 1),
                    _PeriodTile(
                      period: '傍晚 (18:00-22:00)',
                      minutes: distribution.evening,
                      color: Colors.orange,
                    ),
                    const Divider(height: 1),
                    _PeriodTile(
                      period: '夜间 (22:00-06:00)',
                      minutes: distribution.night,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 时间段列表项
class _PeriodTile extends StatelessWidget {
  final String period;
  final int minutes;
  final Color color;

  const _PeriodTile({
    required this.period,
    required this.minutes,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(period),
      trailing: Text(
        hours > 0 ? '${hours}h ${mins}m' : '${mins}m',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 活动标签页
class _ActivitiesTab extends ConsumerWidget {
  const _ActivitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(topActivitiesProvider);

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(child: Text('暂无活动数据'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final percentage = 100.0 * activity.minutes / activities.first.minutes;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text('${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activity.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          activity.formattedDuration,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}