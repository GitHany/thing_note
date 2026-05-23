import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 日历事件数据
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final Color color;
  final String type; // 'record', 'reminder', 'block'
  final int? recordId;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.color,
    required this.type,
    this.recordId,
  });

  factory CalendarEvent.fromRecord({
    required int id,
    required String title,
    required DateTime time,
    int durationMinutes = 60,
  }) {
    return CalendarEvent(
      id: 'record_$id',
      title: title,
      startTime: time,
      endTime: time.add(Duration(minutes: durationMinutes)),
      color: Colors.blue,
      type: 'record',
      recordId: id,
    );
  }
}

/// 日历视图 Provider
final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

enum CalendarViewMode { day, week, month }

/// 选中日期
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 日历事件列表
final calendarEventsProvider = FutureProvider.family<List<CalendarEvent>, DateTime>((ref, date) async {
  // 模拟数据
  return [
    CalendarEvent.fromRecord(id: 1, title: '会议', time: date),
    CalendarEvent.fromRecord(id: 2, title: '运动', time: date.add(const Duration(hours: 3))),
  ];
});

/// 时间线数据
final timelineDataProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  return [
    {'time': '09:00', 'title': '晨间计划', 'type': 'activity'},
    {'time': '12:00', 'title': '午餐', 'type': 'habit'},
    {'time': '18:00', 'title': '运动', 'type': 'goal'},
  ];
});