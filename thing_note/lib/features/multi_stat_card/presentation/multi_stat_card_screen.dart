import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Multi-Stat Card Configuration Provider
final multiStatConfigProvider = StateProvider<MultiStatConfig>((ref) => MultiStatConfig());

class MultiStatConfig {
  final bool showRecordCount;
  final bool showStreak;
  final bool showMood;
  final bool showProductivity;
  final bool showTimeDistribution;
  final bool showTagDistribution;

  MultiStatConfig({
    this.showRecordCount = true,
    this.showStreak = true,
    this.showMood = true,
    this.showProductivity = true,
    this.showTimeDistribution = true,
    this.showTagDistribution = true,
  });

  MultiStatConfig copyWith({
    bool? showRecordCount,
    bool? showStreak,
    bool? showMood,
    bool? showProductivity,
    bool? showTimeDistribution,
    bool? showTagDistribution,
  }) {
    return MultiStatConfig(
      showRecordCount: showRecordCount ?? this.showRecordCount,
      showStreak: showStreak ?? this.showStreak,
      showMood: showMood ?? this.showMood,
      showProductivity: showProductivity ?? this.showProductivity,
      showTimeDistribution: showTimeDistribution ?? this.showTimeDistribution,
      showTagDistribution: showTagDistribution ?? this.showTagDistribution,
    );
  }
}

class MultiStatCardScreen extends ConsumerStatefulWidget {
  const MultiStatCardScreen({super.key});

  @override
  ConsumerState<MultiStatCardScreen> createState() => _MultiStatCardScreenState();
}

class _MultiStatCardScreenState extends ConsumerState<MultiStatCardScreen> {
  final _pageController = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('多维度数据统计'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showConfigPanel(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                _buildOverviewPage(),
                _buildProductivityPage(),
                _buildTimeAnalysisPage(),
                _buildTagAnalysisPage(),
              ],
            ),
          ),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {},
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('yyyy年MM月').format(DateTime.now()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('今日记录', '12', Colors.blue, Icons.note)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('本周记录', '86', Colors.green, Icons.calendar_today)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('连续打卡', '7天', Colors.orange, Icons.local_fire_department)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('平均时长', '45分钟', Colors.purple, Icons.timer)),
            ],
          ),
          const SizedBox(height: 24),
          _buildWeeklyTrendChart(),
        ],
      ),
    );
  }

  Widget _buildProductivityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProductivityScoreCard(),
          const SizedBox(height: 16),
          _buildProductivityBreakdown(),
          const SizedBox(height: 16),
          _buildProductivityTrendChart(),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimeDistributionChart(),
          const SizedBox(height: 16),
          _buildPeakHoursCard(),
          const SizedBox(height: 16),
          _buildActivityHeatmap(),
        ],
      ),
    );
  }

  Widget _buildTagAnalysisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTagUsageChart(),
          const SizedBox(height: 16),
          _buildTopTagsList(),
          const SizedBox(height: 16),
          _buildTagTrendChart(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '↑ 12%',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周趋势',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 8),
                        FlSpot(1, 12),
                        FlSpot(2, 10),
                        FlSpot(3, 15),
                        FlSpot(4, 11),
                        FlSpot(5, 14),
                        FlSpot(6, 18),
                      ],
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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

  Widget _buildProductivityScoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '今日生产力评分',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: Colors.green,
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      '85',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '优秀',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '效率分析',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildProgressItem('专注时间', 0.75, Colors.blue),
            const SizedBox(height: 12),
            _buildProgressItem('任务完成率', 0.90, Colors.green),
            const SizedBox(height: 12),
            _buildProgressItem('学习时间', 0.65, Colors.orange),
            const SizedBox(height: 12),
            _buildProgressItem('社交互动', 0.45, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(progress * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildProductivityTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '生产力趋势',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barGroups: [
                    _makeBarGroup(0, 72),
                    _makeBarGroup(1, 85),
                    _makeBarGroup(2, 68),
                    _makeBarGroup(3, 90),
                    _makeBarGroup(4, 78),
                    _makeBarGroup(5, 92),
                    _makeBarGroup(6, 85),
                  ],
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
                            return Text(days[value.toInt()]);
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

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Theme.of(context).colorScheme.primary,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildTimeDistributionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '时段分布',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 25, title: '上午', color: Colors.blue),
                    PieChartSectionData(value: 35, title: '下午', color: Colors.green),
                    PieChartSectionData(value: 25, title: '晚上', color: Colors.orange),
                    PieChartSectionData(value: 15, title: '深夜', color: Colors.purple),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高峰时段',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSlot('09:00-11:00', '23条', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeSlot('14:00-16:00', '18条', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeSlot('20:00-22:00', '15条', Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '活动热力图',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: 28,
                itemBuilder: (context, index) {
                  final intensity = (index * 7) % 5;
                  return Container(
                    decoration: BoxDecoration(
                      color: _getHeatmapColor(intensity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('少', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                ...List.generate(5, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _getHeatmapColor(index),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                const Text('多', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHeatmapColor(int intensity) {
    final colors = [
      Colors.grey.shade200,
      Colors.green.shade200,
      Colors.green.shade400,
      Colors.green.shade600,
      Colors.green.shade800,
    ];
    return colors[intensity.clamp(0, 4)];
  }

  Widget _buildTagUsageChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签使用分布',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 30, title: '工作', color: Colors.blue),
                    PieChartSectionData(value: 25, title: '学习', color: Colors.green),
                    PieChartSectionData(value: 20, title: '生活', color: Colors.orange),
                    PieChartSectionData(value: 15, title: '健康', color: Colors.red),
                    PieChartSectionData(value: 10, title: '其他', color: Colors.grey),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTagsList() {
    final tags = [
      {'name': '工作', 'count': 156, 'color': Colors.blue},
      {'name': '学习', 'count': 124, 'color': Colors.green},
      {'name': '生活', 'count': 98, 'color': Colors.orange},
      {'name': '健康', 'count': 67, 'color': Colors.red},
      {'name': '社交', 'count': 45, 'color': Colors.purple},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '热门标签 Top 5',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...tags.asMap().entries.map((entry) {
              final index = entry.key;
              final tag = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: (tag['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tag['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tag['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tag['name'] as String)),
                    Text(
                      '${tag['count']}条',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tag['color'] as Color,
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

  Widget _buildTagTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签趋势',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 20),
                        FlSpot(1, 30),
                        FlSpot(2, 25),
                        FlSpot(3, 40),
                        FlSpot(4, 35),
                        FlSpot(5, 50),
                      ],
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

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDot(0, true),
          const SizedBox(width: 8),
          _buildDot(1, false),
          const SizedBox(width: 8),
          _buildDot(2, false),
          const SizedBox(width: 8),
          _buildDot(3, false),
        ],
      ),
    );
  }

  Widget _buildDot(int index, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _showConfigPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final config = ref.read(multiStatConfigProvider);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '显示配置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('记录数量'),
                  value: config.showRecordCount,
                  onChanged: (value) {
                    ref.read(multiStatConfigProvider.notifier).state =
                        config.copyWith(showRecordCount: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('连续打卡'),
                  value: config.showStreak,
                  onChanged: (value) {
                    ref.read(multiStatConfigProvider.notifier).state =
                        config.copyWith(showStreak: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('情绪分布'),
                  value: config.showMood,
                  onChanged: (value) {
                    ref.read(multiStatConfigProvider.notifier).state =
                        config.copyWith(showMood: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('效率分析'),
                  value: config.showProductivity,
                  onChanged: (value) {
                    ref.read(multiStatConfigProvider.notifier).state =
                        config.copyWith(showProductivity: value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
