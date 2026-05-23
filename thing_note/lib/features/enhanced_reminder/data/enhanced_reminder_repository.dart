import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/enhanced_reminder/domain/enhanced_reminder.dart';

class EnhancedReminderRepository {
  final Database db;

  EnhancedReminderRepository(this.db);

  Future<int> createReminder(EnhancedReminder reminder) async {
    return await db.insert('enhanced_reminders', reminder.toMap());
  }

  Future<List<EnhancedReminder>> getAllReminders() async {
    final maps = await db.query(
      'enhanced_reminders',
      orderBy: 'remind_at ASC',
    );
    return maps.map((m) => EnhancedReminder.fromMap(m)).toList();
  }

  Future<List<EnhancedReminder>> getRemindersForRecord(int recordId) async {
    final maps = await db.query(
      'enhanced_reminders',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'remind_at ASC',
    );
    return maps.map((m) => EnhancedReminder.fromMap(m)).toList();
  }

  Future<List<EnhancedReminder>> getUpcomingReminders({int limit = 10}) async {
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'enhanced_reminders',
      where: 'remind_at >= ? AND is_enabled = 1',
      whereArgs: [now],
      orderBy: 'remind_at ASC',
      limit: limit,
    );
    return maps.map((m) => EnhancedReminder.fromMap(m)).toList();
  }

  Future<List<EnhancedReminder>> getRemindersForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'enhanced_reminders',
      where: 'remind_at >= ? AND remind_at <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'remind_at ASC',
    );
    return maps.map((m) => EnhancedReminder.fromMap(m)).toList();
  }

  Future<int> updateReminder(EnhancedReminder reminder) async {
    return await db.update(
      'enhanced_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    return await db.delete(
      'enhanced_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRemindersForRecord(int recordId) async {
    return await db.delete(
      'enhanced_reminders',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  Future<EnhancedReminder?> snoozeReminder(int id, int minutes) async {
    final maps = await db.query(
      'enhanced_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final reminder = EnhancedReminder.fromMap(maps.first);
    final updatedReminder = reminder.copyWith(
      remindAt: DateTime.now().add(Duration(minutes: minutes)),
      snoozeCount: (reminder.snoozeCount ?? 0) + 1,
    );

    await db.update(
      'enhanced_reminders',
      updatedReminder.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    return updatedReminder;
  }

  Future<int> markAsTriggered(int id) async {
    return await db.update(
      'enhanced_reminders',
      {
        'is_triggered': 1,
        'triggered_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ReminderStats> getStats() async {
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_reminders');
    final triggered = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_reminders WHERE is_triggered = 1');
    final snoozed = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_reminders WHERE snooze_count > 0');
    final avgSnooze = await db.rawQuery('SELECT AVG(snooze_count) as avg FROM enhanced_reminders WHERE snooze_count > 0');

    final now = DateTime.now().toIso8601String();
    final missed = await db.rawQuery(
      'SELECT COUNT(*) as count FROM enhanced_reminders WHERE remind_at < ? AND is_triggered = 0',
      [now],
    );

    return ReminderStats(
      totalReminders: total.first['count'] as int? ?? 0,
      triggeredReminders: triggered.first['count'] as int? ?? 0,
      snoozedReminders: snoozed.first['count'] as int? ?? 0,
      missedReminders: missed.first['count'] as int? ?? 0,
      averageSnoozeMinutes: (avgSnooze.first['avg'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> toggleEnabled(int id, bool enabled) async {
    await db.update(
      'enhanced_reminders',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}