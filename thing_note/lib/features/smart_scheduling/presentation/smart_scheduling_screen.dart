import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class SmartSchedulingScreen extends ConsumerStatefulWidget {
  const SmartSchedulingScreen({super.key});

  @override
  ConsumerState<SmartSchedulingScreen> createState() =>
      _SmartSchedulingScreenState();
}

class _SmartSchedulingScreenState extends ConsumerState<SmartSchedulingScreen> {
  final List<_ScheduleItem> _scheduledItems = [
    _ScheduleItem(
      title: '团队会议',
      time: DateTime.now().add(const Duration(hours: 2)),
      duration: const Duration(minutes: 60),
      type: _ScheduleType.meeting,
      participants: ['张三', '李四', '王五'],
    ),
    _ScheduleItem(
      title: '专注工作',
      time: DateTime.now().add(const Duration(hours: 4)),
      duration: const Duration(minutes: 90),
      type: _ScheduleType.focus,
    ),
    _ScheduleItem(
      title: '午休',
      time: DateTime.now().add(const Duration(hours: 6)),
      duration: const Duration(minutes: 60),
      type: _ScheduleType.breakTime,
    ),
  ];

  final List<_TimeSlot> _suggestedSlots = [
    _TimeSlot(
      start: DateTime.now().add(const Duration(hours: 1)),
      end: DateTime.now().add(const Duration(hours: 2)),
      score: 0.9,
      reason: '最佳专注时段',
    ),
    _TimeSlot(
      start: DateTime.now().add(const Duration(hours: 3)),
      end: DateTime.now().add(const Duration(hours: 4)),
      score: 0.75,
      reason: '低干扰时间',
    ),
    _TimeSlot(
      start: DateTime.now().add(const Duration(days: 1, hours: 9)),
      end: DateTime.now().add(const Duration(days: 1, hours: 10)),
      score: 0.85,
      reason: '明日最佳时段',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.smartScheduling),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showCalendarView(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Smart suggestions
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 智能排程',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '根据您的习惯自动推荐最佳时间',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Suggested time slots
          Text(
            AppLocalizations.of(context)!.suggestedTimeSlots,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...(_suggestedSlots.map((slot) => _buildTimeSlotCard(slot))),
          const SizedBox(height: 24),

          // Quick schedule
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.quickSchedule,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickScheduleChip(
                      label: '15分钟专注',
                      icon: Icons.timer,
                      onTap: () => _quickSchedule(const Duration(minutes: 15)),
                    ),
                    _QuickScheduleChip(
                      label: '30分钟专注',
                      icon: Icons.timer,
                      onTap: () => _quickSchedule(const Duration(minutes: 30)),
                    ),
                    _QuickScheduleChip(
                      label: '1小时专注',
                      icon: Icons.timer,
                      onTap: () => _quickSchedule(const Duration(minutes: 60)),
                    ),
                    _QuickScheduleChip(
                      label: '15分钟休息',
                      icon: Icons.coffee,
                      onTap: () => _quickScheduleBreak(const Duration(minutes: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today's schedule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.todaySchedule,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () => _addToSchedule(),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_scheduledItems.map((item) => _buildScheduleItemCard(item))),
          const SizedBox(height: 24),

          // Conflict detection
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.conflictDetection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_busy, color: Colors.red),
                  title: const Text('会议时间冲突'),
                  subtitle: const Text('团队会议与个人任务时间重叠'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Optimal time finder
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.findOptimalTime,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const TextField(
                        decoration: InputDecoration(
                          labelText: '任务名称',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.task),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.timer),
                              label: const Text('时长'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.search),
                              label: const Text('查找最佳时间'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(_TimeSlot slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectTimeSlot(slot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getScoreColor(slot.score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${(slot.score * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(slot.score),
                      ),
                    ),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTimeRange(slot.start, slot.end),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      slot.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => _selectTimeSlot(slot),
                child: const Text('选择'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItemCard(_ScheduleItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(item.type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTypeIcon(item.type),
            color: _getTypeColor(item.type),
          ),
        ),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTime(item.time)),
            if (item.participants.isNotEmpty)
              Text(
                item.participants.join(', '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getTypeIcon(_ScheduleType type) {
    switch (type) {
      case _ScheduleType.meeting:
        return Icons.people;
      case _ScheduleType.focus:
        return Icons.timer;
      case _ScheduleType.breakTime:
        return Icons.coffee;
      case _ScheduleType.task:
        return Icons.task;
    }
  }

  Color _getTypeColor(_ScheduleType type) {
    switch (type) {
      case _ScheduleType.meeting:
        return Colors.blue;
      case _ScheduleType.focus:
        return Colors.green;
      case _ScheduleType.breakTime:
        return Colors.orange;
      case _ScheduleType.task:
        return Colors.purple;
    }
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _selectTimeSlot(_TimeSlot slot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已选择: ${_formatTimeRange(slot.start, slot.end)}')),
    );
  }

  void _quickSchedule(Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已安排 ${duration.inMinutes} 分钟专注')),
    );
  }

  void _quickScheduleBreak(Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已安排 ${duration.inMinutes} 分钟休息')),
    );
  }

  void _addToSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打开添加日程对话框')),
    );
  }

  void _showCalendarView() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打开日历视图')),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('工作时段设置'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('专注偏好'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.breakfast_dining),
            title: const Text('休息时间'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

enum _ScheduleType { meeting, focus, breakTime, task }

class _TimeSlot {
  final DateTime start;
  final DateTime end;
  final double score;
  final String reason;

  _TimeSlot({
    required this.start,
    required this.end,
    required this.score,
    required this.reason,
  });
}

class _ScheduleItem {
  final String title;
  final DateTime time;
  final Duration duration;
  final _ScheduleType type;
  final List<String> participants;

  _ScheduleItem({
    required this.title,
    required this.time,
    required this.duration,
    required this.type,
    this.participants = const [],
  });
}

class _QuickScheduleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickScheduleChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}