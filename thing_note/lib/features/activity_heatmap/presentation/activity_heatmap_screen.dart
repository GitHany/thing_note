import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/activity_heatmap/data/activity_heatmap_repository.dart';

class ActivityHeatmapScreen extends ConsumerStatefulWidget {
  const ActivityHeatmapScreen({super.key});

  @override
  ConsumerState<ActivityHeatmapScreen> createState() => _ActivityHeatmapScreenState();
}

class _ActivityHeatmapScreenState extends ConsumerState<ActivityHeatmapScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  Map<int, int> _dayCounts = {};
  List<Map<String, dynamic>> _hourlyDistribution = [];
  Map<String, int> _weeklyDistribution = {};
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(activityHeatmapRepositoryProvider);
    
    final results = await Future.wait([
      repo.getDayActivityCounts(_selectedYear, _selectedMonth),
      repo.getHourlyDistribution(_selectedYear, _selectedMonth),
      repo.getWeeklyDistribution(_selectedYear, _selectedMonth),
      repo.getActivityStats(_selectedYear, _selectedMonth),
    ]);
    
    setState(() {
      _dayCounts = results[0] as Map<int, int>;
      _hourlyDistribution = results[1] as List<Map<String, dynamic>>;
      _weeklyDistribution = results[2] as Map<String, int>;
      _stats = results[3] as Map<String, dynamic>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活动热力图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateHeatmap,
            tooltip: '更新数据',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 24),
                  _buildCalendarHeatmap(),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildHourlyChart(),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                });
                _loadData();
              },
            ),
            Text(
              '$_selectedYear 年 $_selectedMonth 月',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final now = DateTime.now();
                if (_selectedYear < now.year || 
                    (_selectedYear == now.year && _selectedMonth < now.month)) {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                  });
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeatmap() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    // Calculate max for intensity
    final maxCount = _dayCounts.values.isEmpty 
        ? 1 
        : _dayCounts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '每日活动',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['一', '二', '三', '四', '五', '六', '日']
                  .map((d) => SizedBox(
                        width: 36,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42, // 6 weeks
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                if (dayOffset < 1 || dayOffset > daysInMonth) {
                  return const SizedBox();
                }
                
                final count = _dayCounts[dayOffset] ?? 0;
                final intensity = maxCount > 0 ? count / maxCount : 0.0;
                
                return Tooltip(
                  message: '$dayOffset 日: $count 条记录',
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getHeatColor(intensity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        dayOffset.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: intensity > 0.5 ? Colors.white : Colors.grey[800],
                          fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('少', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 8),
                ...List.generate(5, (i) {
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _getHeatColor(i / 4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                const Text('多', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHeatColor(double intensity) {
    if (intensity == 0) return Colors.grey[200]!;
    if (intensity < 0.25) return Colors.green[200]!;
    if (intensity < 0.5) return Colors.green[400]!;
    if (intensity < 0.75) return Colors.green[600]!;
    return Colors.green[800]!;
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: '总记录数',
            value: '${_stats['totalRecords'] ?? 0}',
            icon: Icons.list_alt,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: '日均记录',
            value: (_stats['avgDaily'] as double?)?.toStringAsFixed(1) ?? '0',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: '最高日',
            value: '${_stats['maxDaily'] ?? 0}',
            icon: Icons.emoji_events,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyChart() {
    if (_hourlyDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = _hourlyDistribution.map((data) {
      final hour = data['hour'] as int;
      final total = data['total'] as int;
      return FlSpot(hour.toDouble(), total.toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '每小时分布',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 6 == 0) {
                            return Text('${value.toInt()}时', style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 20,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = _weeklyDistribution.values.toList();
    final maxVal = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '每周分布',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                          if (value >= 0 && value < 7) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklyDistribution.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value.toDouble(),
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  maxY: maxVal.toDouble() * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateHeatmap() async {
    final repo = ref.read(activityHeatmapRepositoryProvider);
    await repo.updateHeatmapFromRecords();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('热力图数据已更新')),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}