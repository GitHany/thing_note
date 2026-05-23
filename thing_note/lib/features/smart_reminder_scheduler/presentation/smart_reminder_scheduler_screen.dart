import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Smart Reminder Scheduler State
enum ReminderScheduleType { once, daily, weekly, monthly, smart }

class ReminderSchedule {
  final ReminderScheduleType type;
  final DateTime? scheduledTime;
  final String? preferredTime;
  final int? smartOffset;
  final bool isActive;

  ReminderSchedule({
    this.type = ReminderScheduleType.once,
    this.scheduledTime,
    this.preferredTime,
    this.smartOffset,
    this.isActive = true,
  });
}

// Smart Reminder Config Provider
final smartReminderConfigProvider = StateProvider<SmartReminderConfig>((ref) {
  return SmartReminderConfig(
    enabled: true,
    preferredTimes: ['09:00', '14:00', '20:00'],
    smartScheduling: true,
    contextAware: true,
    learningEnabled: true,
  );
});

class SmartReminderConfig {
  final bool enabled;
  final List<String> preferredTimes;
  final bool smartScheduling;
  final bool contextAware;
  final bool learningEnabled;

  SmartReminderConfig({
    this.enabled = true,
    this.preferredTimes = const ['09:00', '14:00', '20:00'],
    this.smartScheduling = true,
    this.contextAware = true,
    this.learningEnabled = true,
  });

  SmartReminderConfig copyWith({
    bool? enabled,
    List<String>? preferredTimes,
    bool? smartScheduling,
    bool? contextAware,
    bool? learningEnabled,
  }) {
    return SmartReminderConfig(
      enabled: enabled ?? this.enabled,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      smartScheduling: smartScheduling ?? this.smartScheduling,
      contextAware: contextAware ?? this.contextAware,
      learningEnabled: learningEnabled ?? this.learningEnabled,
    );
  }
}

class SmartReminderSchedulerScreen extends ConsumerStatefulWidget {
  const SmartReminderSchedulerScreen({super.key});

  @override
  ConsumerState<SmartReminderSchedulerScreen> createState() => _SmartReminderSchedulerScreenState();
}

class _SmartReminderSchedulerScreenState extends ConsumerState<SmartReminderSchedulerScreen> {
  ReminderScheduleType _selectedType = ReminderScheduleType.once;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  String _suggestedTime = '09:00';
  bool _useSmartSuggestion = true;

  @override
  void initState() {
    super.initState();
    _calculateSmartSuggestion();
  }

  void _calculateSmartSuggestion() {
    // Simple smart algorithm to suggest best time based on patterns
    final now = DateTime.now();
    if (now.hour < 12) {
      _suggestedTime = '09:00';
    } else if (now.hour < 17) {
      _suggestedTime = '14:00';
    } else if (now.hour < 21) {
      _suggestedTime = '20:00';
    } else {
      _suggestedTime = '明天 09:00';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能提醒调度'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSmartSuggestionCard(),
            const SizedBox(height: 16),
            _buildScheduleTypeSelector(),
            const SizedBox(height: 16),
            _buildDateTimePicker(),
            const SizedBox(height: 16),
            _buildReminderContent(),
            const SizedBox(height: 16),
            _buildReminderPreview(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSmartSuggestionCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                  '智能建议',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '根据你的使用习惯，我们建议将提醒设置为 $_suggestedTime',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: _useSmartSuggestion,
                  onChanged: (value) {
                    setState(() {
                      _useSmartSuggestion = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildSuggestionChip('上午 9:00', '最佳专注时间'),
                _buildSuggestionChip('下午 2:00', '工作间隙'),
                _buildSuggestionChip('晚上 8:00', '回顾时间'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String time, String reason) {
    return ActionChip(
      avatar: const Icon(Icons.schedule, size: 16),
      label: Text(time),
      onPressed: () {
        setState(() {
          _selectedTime = TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1]),
          );
          _suggestedTime = time;
        });
      },
    );
  }

  Widget _buildScheduleTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '提醒类型',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip(ReminderScheduleType.once, '一次性', Icons.looks_one),
                _buildTypeChip(ReminderScheduleType.daily, '每天', Icons.repeat),
                _buildTypeChip(ReminderScheduleType.weekly, '每周', Icons.date_range),
                _buildTypeChip(ReminderScheduleType.monthly, '每月', Icons.calendar_month),
                _buildTypeChip(ReminderScheduleType.smart, '智能', Icons.auto_awesome),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ReminderScheduleType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : null,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
    );
  }

  Widget _buildDateTimePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置时间',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('日期'),
              subtitle: Text(DateFormat('yyyy年MM月dd日').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('时间'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '提醒内容',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: '输入提醒内容...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '支持关联记录、标签、位置等信息',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPreview() {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预览',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '提醒',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              DateFormat('MM月dd日 HH:mm').format(scheduledDateTime),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _getTypeBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTypeBadge() {
    String label;
    Color color;
    switch (_selectedType) {
      case ReminderScheduleType.once:
        label = '一次性';
        color = Colors.blue;
        break;
      case ReminderScheduleType.daily:
        label = '每天';
        color = Colors.green;
        break;
      case ReminderScheduleType.weekly:
        label = '每周';
        color = Colors.orange;
        break;
      case ReminderScheduleType.monthly:
        label = '每月';
        color = Colors.purple;
        break;
      case ReminderScheduleType.smart:
        label = '智能';
        color = Colors.pink;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedType = ReminderScheduleType.once;
                    _selectedDate = DateTime.now();
                    _selectedTime = TimeOfDay.now();
                  });
                },
                child: const Text('重置'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _saveReminder(),
                child: const Text('创建提醒'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveReminder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提醒已创建')),
    );
    context.pop();
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final config = ref.read(smartReminderConfigProvider);
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
                  '智能提醒设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用智能提醒'),
                  subtitle: const Text('根据习惯自动优化提醒时间'),
                  value: config.enabled,
                  onChanged: (value) {
                    ref.read(smartReminderConfigProvider.notifier).state =
                        config.copyWith(enabled: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('智能调度'),
                  subtitle: const Text('分析最佳提醒时间'),
                  value: config.smartScheduling,
                  onChanged: (value) {
                    ref.read(smartReminderConfigProvider.notifier).state =
                        config.copyWith(smartScheduling: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('情境感知'),
                  subtitle: const Text('根据位置和活动设置提醒'),
                  value: config.contextAware,
                  onChanged: (value) {
                    ref.read(smartReminderConfigProvider.notifier).state =
                        config.copyWith(contextAware: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('学习模式'),
                  subtitle: const Text('从你的行为中学习优化提醒'),
                  value: config.learningEnabled,
                  onChanged: (value) {
                    ref.read(smartReminderConfigProvider.notifier).state =
                        config.copyWith(learningEnabled: value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('保存设置'),
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
