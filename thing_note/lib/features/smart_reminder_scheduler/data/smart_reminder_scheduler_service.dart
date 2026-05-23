import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/smart_reminder_scheduler_models.dart';

/// 智能提醒调度服务提供者
final smartReminderSchedulerProvider = Provider<SmartReminderSchedulerService>((ref) {
  return SmartReminderSchedulerService(ref.read(databaseProvider.future));
});

/// 智能提醒调度服务
class SmartReminderSchedulerService {
  final Future<Database> _db;

  SmartReminderSchedulerService(this._db);

  /// 获取今天的调度提醒
  Future<List<ReminderSchedule>> getTodaySchedules() async {
    final db = await _db;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final rows = await db.query(
      'reminder_schedules',
      where: 'scheduled_time >= ? AND scheduled_time < ? AND is_enabled = 1',
      whereArgs: [todayStart.toIso8601String(), todayEnd.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );

    return rows.map((r) => ReminderSchedule.fromMap({'id': r['id'], ...r})).toList();
  }

  /// 创建提醒调度
  Future<int> createSchedule(ReminderSchedule schedule) async {
    final db = await _db;

    final id = await db.insert('reminder_schedules', {
      ...schedule.toMap(),
      'created_at': DateTime.now().toIso8601String(),
    });

    return id;
  }

  /// 更新调度
  Future<void> updateSchedule(ReminderSchedule schedule) async {
    final db = await _db;
    await db.update(
      'reminder_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// 删除调度
  Future<void> deleteSchedule(int id) async {
    final db = await _db;
    await db.delete(
      'reminder_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有调度
  Future<List<ReminderSchedule>> getAllSchedules() async {
    final db = await _db;
    final rows = await db.query(
      'reminder_schedules',
      orderBy: 'scheduled_time ASC',
    );

    return rows.map((r) => ReminderSchedule.fromMap({'id': r['id'], ...r})).toList();
  }

  /// 检测冲突
  Future<List<ScheduleConflict>> detectConflicts() async {
    final schedules = await getAllSchedules();
    final conflicts = <ScheduleConflict>[];

    // 按时间分组
    final timeGroups = <String, List<ReminderSchedule>>{};
    for (final schedule in schedules) {
      final key = schedule.scheduledTime.toIso8601String();
      timeGroups.putIfAbsent(key, () => []);
      timeGroups[key]!.add(schedule);
    }

    // 找出冲突
    for (final entry in timeGroups.entries) {
      if (entry.value.length > 1) {
        conflicts.add(ScheduleConflict(
          time: DateTime.parse(entry.key),
          conflictingReminders: entry.value,
          resolution: '建议推迟部分提醒',
        ));
      }
    }

    return conflicts;
  }

  /// 智能排程
  Future<List<ReminderSchedule>> smartSchedule(List<ReminderSchedule> reminders) async {
    // 简单实现：将提醒均匀分布
    final scheduled = <ReminderSchedule>[];
    final now = DateTime.now();
    var currentTime = DateTime(now.year, now.month, now.day, 9, 0); // 从早上9点开始

    for (final reminder in reminders) {
      // 跳过已禁用的
      if (!reminder.isEnabled) continue;

      // 找到下一个可用时间槽
      while (_isSlotTaken(scheduled, currentTime)) {
        currentTime = currentTime.add(const Duration(minutes: 30));
      }

      scheduled.add(ReminderSchedule(
        id: reminder.id,
        title: reminder.title,
        scheduledTime: currentTime,
        type: reminder.type,
        isEnabled: reminder.isEnabled,
        linkedRecordId: reminder.linkedRecordId,
        priority: reminder.priority,
      ));

      // 根据优先级调整间隔
      final interval = _getIntervalForPriority(reminder.priority);
      currentTime = currentTime.add(Duration(minutes: interval));
    }

    return scheduled;
  }

  bool _isSlotTaken(List<ReminderSchedule> schedules, DateTime time) {
    for (final schedule in schedules) {
      final diff = schedule.scheduledTime.difference(time).inMinutes.abs();
      if (diff < 30) return true;
    }
    return false;
  }

  int _getIntervalForPriority(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.urgent:
        return 15;
      case ReminderPriority.high:
        return 20;
      case ReminderPriority.normal:
        return 30;
      case ReminderPriority.low:
        return 45;
    }
  }

  /// 获取调度统计
  Future<Map<String, int>> getScheduleStats() async {
    final db = await _db;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM reminder_schedules'),
    ) ?? 0;

    final today = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM reminder_schedules WHERE date(scheduled_time) = date('now')",
      ),
    ) ?? 0;

    final enabled = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM reminder_schedules WHERE is_enabled = 1'),
    ) ?? 0;

    return {
      'total': total,
      'today': today,
      'enabled': enabled,
    };
  }

  /// 启用/禁用调度
  Future<void> toggleSchedule(int id, bool enabled) async {
    final db = await _db;
    await db.update(
      'reminder_schedules',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}