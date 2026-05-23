import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_summary_widget/data/daily_summary_repository.dart';
import 'package:thing_note/features/daily_summary_widget/domain/daily_summary.dart';

class DailySummaryWidgetScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const DailySummaryWidgetScreen({super.key, this.initialDate});

  @override
  ConsumerState<DailySummaryWidgetScreen> createState() => _DailySummaryWidgetScreenState();
}

class _DailySummaryWidgetScreenState extends ConsumerState<DailySummaryWidgetScreen> {
  late DateTime _selectedDate;
  DailySummary? _summary;
  Map<String, dynamic> _weeklyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(dailySummaryRepositoryProvider);
    
    final results = await Future.wait([
      repo.getOrGenerateSummary(_selectedDate),
      repo.getWeeklyStats(),
    ]);
    
    setState(() {
      _summary = results[0] as DailySummary;
      _weeklyStats = results[1] as Map<String, dynamic>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日摘要'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSummary,
            tooltip: '刷新',
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
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildTodaySummary(),
                  const SizedBox(height: 24),
                  _buildWeeklyOverview(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
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
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
                _loadData();
              },
            ),
            GestureDetector(
              onTap: () => _selectDate(),
              child: Column(
                children: [
                  Text(
                    _isToday(_selectedDate) ? '今天' : _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatFullDate(_selectedDate),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                  ? () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                      _loadData();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '今日概览',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.list_alt,
                  value: '${_summary?.recordCount ?? 0}',
                  label: '记录数',
                  color: Colors.blue,
                ),
                _SummaryItem(
                  icon: Icons.timer,
                  value: _summary?.formattedDuration ?? '0m',
                  label: '总时长',
                  color: Colors.green,
                ),
                _SummaryItem(
                  icon: Icons.emoji_events,
                  value: '${_summary?.completedGoals ?? 0}',
                  label: '完成目标',
                  color: Colors.orange,
                ),
              ],
            ),
            if (_summary?.topThingName != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '最常用: ${_summary!.topThingName}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (_summary?.moodScore != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.mood, size: 16, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    '情绪评分: ${_summary!.moodScore!.toStringAsFixed(1)}/5',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final totalRecords = _weeklyStats['totalRecords'] as int? ?? 0;
    final totalMinutes = _weeklyStats['totalMinutes'] as int? ?? 0;
    final avgRecords = (_weeklyStats['avgRecords'] as double?)?.toStringAsFixed(1) ?? '0';
    final maxRecords = _weeklyStats['maxRecords'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_view_week, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '本周统计',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox(
                  label: '总记录',
                  value: '$totalRecords',
                  icon: Icons.list_alt,
                  color: Colors.blue,
                ),
                _StatBox(
                  label: '总时长',
                  value: _formatMinutes(totalMinutes),
                  icon: Icons.timer,
                  color: Colors.green,
                ),
                _StatBox(
                  label: '日均',
                  value: avgRecords,
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
                _StatBox(
                  label: '最高日',
                  value: '$maxRecords',
                  icon: Icons.emoji_events,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '快捷操作',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(
                  icon: Icons.add,
                  label: '新建记录',
                  onTap: () => _navigateTo('/record/new'),
                ),
                _ActionChip(
                  icon: Icons.search,
                  label: '搜索记录',
                  onTap: () => _navigateTo('/search'),
                ),
                _ActionChip(
                  icon: Icons.bar_chart,
                  label: '查看统计',
                  onTap: () => _navigateTo('/statistics'),
                ),
                _ActionChip(
                  icon: Icons.calendar_today,
                  label: '日历视图',
                  onTap: () => _navigateTo('/calendar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  Future<void> _refreshSummary() async {
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('摘要已刷新')),
      );
    }
  }

  void _navigateTo(String path) {
    // Navigate using GoRouter or Navigator
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导航到 $path')),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatFullDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.year}年${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h${mins}m';
    }
    return '${mins}m';
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}