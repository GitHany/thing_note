import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarEnhancedScreen extends ConsumerStatefulWidget {
  const CalendarEnhancedScreen({super.key});

  @override
  ConsumerState<CalendarEnhancedScreen> createState() => _CalendarEnhancedScreenState();
}

class _CalendarEnhancedScreenState extends ConsumerState<CalendarEnhancedScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强日历'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_agenda),
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: CalendarFormat.month, child: Text('月视图')),
              const PopupMenuItem(value: CalendarFormat.twoWeeks, child: Text('双周视图')),
              const PopupMenuItem(value: CalendarFormat.week, child: Text('周视图')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportCalendar(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _buildDayEvents(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      eventLoader: (day) => _getEventsForDay(day),
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    // Simulated events
    if (day.day % 3 == 0) {
      return [
        {'title': '团队会议', 'time': '10:00', 'color': Colors.blue},
        {'title': '健身', 'time': '18:00', 'color': Colors.green},
      ];
    } else if (day.day % 2 == 0) {
      return [
        {'title': '学习', 'time': '14:00', 'color': Colors.purple},
      ];
    }
    return [];
  }

  Widget _buildDayEvents() {
    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDay != null
                    ? '${_selectedDay!.month}月${_selectedDay!.day}日'
                    : '选择一个日期',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _addEvent(),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '今日无事件',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: event['color'] as Color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(event['title'] as String),
                        subtitle: Text(event['time'] as String),
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {},
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加事件')),
    );
  }

  void _exportCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出日历...')),
    );
  }
}