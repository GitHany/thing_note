import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/calendar_models.dart';

/// 智能日历视图
class SmartCalendarScreen extends ConsumerWidget {
  const SmartCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final eventsAsync = ref.watch(calendarEventsProvider(selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能日历'),
        actions: [
          SegmentedButton<CalendarViewMode>(
            segments: const [
              ButtonSegment(value: CalendarViewMode.day, icon: Icon(Icons.view_day)),
              ButtonSegment(value: CalendarViewMode.week, icon: Icon(Icons.view_week)),
              ButtonSegment(value: CalendarViewMode.month, icon: Icon(Icons.calendar_month)),
            ],
            selected: {viewMode},
            onSelectionChanged: (set) {
              ref.read(calendarViewModeProvider.notifier).state = set.first;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 日历选择器
          CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
          const Divider(),
          // 事件列表
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('加载失败')),
              data: (events) => events.isEmpty
                  ? const Center(child: Text('今天没有记录'))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: event.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(event.type == 'record' ? Icons.event_note : Icons.alarm, color: event.color),
                          ),
                          title: Text(event.title),
                          subtitle: Text('${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}'),
                          trailing: event.recordId != null
                              ? IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => context.push('/record/${event.recordId}'),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}