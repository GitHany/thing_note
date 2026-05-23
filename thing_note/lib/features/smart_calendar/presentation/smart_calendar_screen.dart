import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_calendar/data/smart_calendar_repository.dart';
import 'package:thing_note/features/smart_calendar/domain/smart_calendar_event.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final smartCalendarProvider = Provider((ref) => ref.watch(smartCalendarRepositoryProvider));

class SmartCalendarScreen extends ConsumerStatefulWidget {
  const SmartCalendarScreen({super.key});

  @override
  ConsumerState<SmartCalendarScreen> createState() => _SmartCalendarScreenState();
}

class _SmartCalendarScreenState extends ConsumerState<SmartCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<SmartCalendarEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final repo = ref.read(smartCalendarProvider);
    final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
    _events = await repo.getEventsByDateRange(start, end);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smartCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() => _selectedDate = DateTime.now());
              _loadEvents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
              children: [
                Expanded(flex: 2, child: _buildCalendar()),
                Expanded(flex: 3, child: _buildEventList()),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendar(),
                  _buildEventList(),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                    });
                    _loadEvents();
                  },
                ),
                Text(
                  '${_selectedDate.year}年${_selectedDate.month}月',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                    });
                    _loadEvents();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    final days = <Widget>[];
    
    // Weekday headers
    const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    for (final day in weekDays) {
      days.add(Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold))));
    }

    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    // Calendar days
    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final hasEvents = _events.any((e) =>
          e.startTime.year == date.year &&
          e.startTime.month == date.month &&
          e.startTime.day == date.day);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;

      days.add(GestureDetector(
        onTap: () {
          setState(() => _selectedDate = date);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
              if (hasEvents)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.secondary,
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: days,
    );
  }

  Widget _buildEventList() {
    final dayEvents = _events.where((e) =>
        e.startTime.year == _selectedDate.year &&
        e.startTime.month == _selectedDate.month &&
        e.startTime.day == _selectedDate.day).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedDate.month}月${_selectedDate.day}日的事件',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (dayEvents.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.event_available, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('这一天没有事件'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _showAddEventDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('添加事件'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayEvents.length,
              itemBuilder: (context, index) {
                final event = dayEvents[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(event.color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      event.isAllDay
                          ? '全天'
                          : '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}${event.endTime != null ? ' - ${event.endTime!.hour}:${event.endTime!.minute.toString().padLeft(2, '0')}' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteEvent(event.id!),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    bool isAllDay = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加事件'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '事件标题',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('全天事件'),
                  value: isAllDay,
                  onChanged: (value) => setDialogState(() => isAllDay = value),
                ),
                if (!isAllDay)
                  ListTile(
                    title: const Text('开始时间'),
                    trailing: Text('${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final event = SmartCalendarEvent(
                  title: titleController.text,
                  startTime: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    isAllDay ? 0 : startTime.hour,
                    isAllDay ? 0 : startTime.minute,
                  ),
                  isAllDay: isAllDay,
                );
                await ref.read(smartCalendarProvider).insertEvent(event);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadEvents();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    await ref.read(smartCalendarProvider).deleteEvent(id);
    _loadEvents();
  }
}