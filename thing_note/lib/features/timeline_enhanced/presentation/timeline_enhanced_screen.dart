import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:thing_note/core/database/database_provider.dart';

class TimelineEnhancedScreen extends ConsumerStatefulWidget {
  const TimelineEnhancedScreen({super.key});

  @override
  ConsumerState<TimelineEnhancedScreen> createState() => _TimelineEnhancedScreenState();
}

class _TimelineEnhancedScreenState extends ConsumerState<TimelineEnhancedScreen> {
  String _viewMode = 'week';
  final DateTime _currentDate = DateTime.now();
  Map<DateTime, int> _recordCounts = {};

  @override
  void initState() {
    super.initState();
    _loadRecordCounts();
  }

  Future<void> _loadRecordCounts() async {
    final db = await ref.read(databaseProvider.future);
    final results = await db.rawQuery('''
      SELECT date(occurred_at) as day, COUNT(*) as count 
      FROM episode_records 
      GROUP BY date(occurred_at)
    ''');

    setState(() {
      _recordCounts = {
        for (final row in results)
          DateTime.parse(row['day'] as String): row['count'] as int
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强时间线'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_agenda),
            onSelected: (value) {
              setState(() {
                _viewMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('本周')),
              const PopupMenuItem(value: 'month', child: Text('本月')),
              const PopupMenuItem(value: 'year', child: Text('本年')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Heatmap calendar
          _buildCalendarHeatmap(),
          const Divider(),
          // Stats
          _buildStats(),
          const Divider(),
          // Timeline view
          Expanded(
            child: _buildTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeatmap() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: _viewMode == 'week'
          ? _buildWeekView()
          : _viewMode == 'month'
              ? _buildMonthView()
              : _buildYearView(),
    );
  }

  Widget _buildWeekView() {
    final weekDays = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });

    final maxCount = _recordCounts.values.isEmpty 
        ? 1 
        : _recordCounts.values.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekDays.map((date) {
        final count = _recordCounts[DateTime(date.year, date.month, date.day)] ?? 0;
        final intensity = maxCount > 0 ? count / maxCount : 0.0;

        return Column(
          children: [
            Text(
              DateFormat('E').format(date).substring(0, 1),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getHeatmapColor(intensity),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  count > 0 ? count.toString() : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthView() {
    final firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final date = DateTime(firstDay.year, firstDay.month, index + 1);
        final count = _recordCounts[date] ?? 0;
        final maxCount = _recordCounts.values.isEmpty 
            ? 1 
            : _recordCounts.values.reduce((a, b) => a > b ? a : b);
        final intensity = maxCount > 0 ? count / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _getHeatmapColor(intensity),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: intensity > 0.5 ? Colors.white : Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearView() {
    final months = List.generate(12, (i) => i + 1);
    final maxCount = _recordCounts.values.isEmpty 
        ? 1 
        : _recordCounts.values.reduce((a, b) => a > b ? a : b);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = months[index];
        final monthRecords = _recordCounts.entries
            .where((e) => e.key.month == month && e.key.year == _currentDate.year)
            .fold(0, (sum, e) => sum + e.value);
        final intensity = maxCount > 0 ? monthRecords / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getHeatmapColor(intensity),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$month月',
              style: TextStyle(
                color: intensity > 0.5 ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) return Colors.grey.shade200;
    if (intensity < 0.25) return Colors.green.shade200;
    if (intensity < 0.5) return Colors.green.shade400;
    if (intensity < 0.75) return Colors.green.shade600;
    return Colors.green.shade800;
  }

  Widget _buildStats() {
    final totalDays = _recordCounts.length;
    final totalRecords = _recordCounts.values.fold(0, (a, b) => a + b);
    final avgPerDay = totalDays > 0 ? (totalRecords / totalDays).toStringAsFixed(1) : '0';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCard(label: '活跃天数', value: totalDays.toString()),
          _StatCard(label: '总记录数', value: totalRecords.toString()),
          _StatCard(label: '日均', value: avgPerDay),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final records = _getRecordsForView();

    if (records.isEmpty) {
      return const Center(child: Text('暂无记录'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _TimelineItem(
          record: records[index],
          isFirst: index == 0,
          isLast: index == records.length - 1,
        );
      },
    );
  }

  List<Map<String, dynamic>> _getRecordsForView() {
    // This would normally fetch from database
    return [];
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.record,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: 40,
          child: Column(
            children: [
              if (!isFirst)
                Container(width: 2, height: 20, color: Colors.grey.shade300),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: Colors.grey.shade300),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['note'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record['time'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}