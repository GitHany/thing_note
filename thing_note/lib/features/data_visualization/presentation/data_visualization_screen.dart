import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

class DataVisualizationScreen extends ConsumerStatefulWidget {
  const DataVisualizationScreen({super.key});

  @override
  ConsumerState<DataVisualizationScreen> createState() => _DataVisualizationScreenState();
}

class _DataVisualizationScreenState extends ConsumerState<DataVisualizationScreen> {
  String _selectedChartType = 'pie';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据可视化中心'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportChart(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildChartTypeSelector(),
          Expanded(
            child: _buildChart(),
          ),
          _buildChartStats(),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    final chartTypes = [
      {'type': 'pie', 'icon': Icons.pie_chart, 'label': '饼图'},
      {'type': 'bar', 'icon': Icons.bar_chart, 'label': '柱状图'},
      {'type': 'line', 'icon': Icons.show_chart, 'label': '折线图'},
      {'type': 'heatmap', 'icon': Icons.grid_on, 'label': '热力图'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: chartTypes.map((chart) {
          final isSelected = _selectedChartType == chart['type'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChartType = chart['type'] as String;
              });
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    chart['icon'] as IconData,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chart['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    switch (_selectedChartType) {
      case 'pie':
        return _buildPieChart();
      case 'bar':
        return _buildBarChart();
      case 'line':
        return _buildLineChart();
      case 'heatmap':
        return _buildHeatmap();
      default:
        return _buildPieChart();
    }
  }

  Widget _buildPieChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: 35, title: '35%', color: Colors.blue),
            PieChartSectionData(value: 25, title: '25%', color: Colors.green),
            PieChartSectionData(value: 20, title: '20%', color: Colors.orange),
            PieChartSectionData(value: 12, title: '12%', color: Colors.purple),
            PieChartSectionData(value: 8, title: '8%', color: Colors.red),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][value.toInt()],
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 45)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 80)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 55)]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 70)]),
            BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 30)]),
            BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 25)]),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text('${(value * 3).toInt()}日'),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: 10,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 30),
                FlSpot(1, 45),
                FlSpot(2, 52),
                FlSpot(3, 48),
                FlSpot(4, 65),
                FlSpot(5, 72),
                FlSpot(6, 68),
                FlSpot(7, 75),
                FlSpot(8, 82),
                FlSpot(9, 78),
                FlSpot(10, 90),
              ],
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 35,
        itemBuilder: (context, index) {
          final intensity = (index % 7 + index ~/ 7) / 10;
          return Container(
            decoration: BoxDecoration(
              color: Color.lerp(Colors.grey[200], Colors.green, intensity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: intensity > 0.5 ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '统计概览',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总记录', '1,234', Icons.description),
              _buildStatItem('本周新增', '45', Icons.add_circle),
              _buildStatItem('活跃天数', '28', Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('工作: 35%'), avatar: Icon(Icons.work, size: 18)),
              Chip(label: Text('学习: 25%'), avatar: Icon(Icons.school, size: 18)),
              Chip(label: Text('运动: 20%'), avatar: Icon(Icons.fitness_center, size: 18)),
              Chip(label: Text('娱乐: 12%'), avatar: Icon(Icons.movie, size: 18)),
              Chip(label: Text('其他: 8%'), avatar: Icon(Icons.more_horiz, size: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
  }

  void _exportChart() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图表导出中...')),
    );
  }
}