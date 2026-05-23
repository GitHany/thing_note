import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/reminder_analytics/domain/reminder_analytics_entry.dart';

final reminderAnalyticsRepositoryProvider = Provider<ReminderAnalyticsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ReminderAnalyticsRepository(dbAsync);
});

class ReminderAnalyticsRepository {
  final AsyncValue<Database> _dbAsync;

  ReminderAnalyticsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insert(ReminderAnalyticsEntry entry) async {
    final db = await _db;
    return await db.insert('reminder_analytics', entry.toMap());
  }

  Future<List<ReminderAnalyticsEntry>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_analytics',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReminderAnalyticsEntry.fromMap(map)).toList();
  }

  Future<List<ReminderAnalyticsEntry>> getByReminderId(int reminderId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_analytics',
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReminderAnalyticsEntry.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getOverview() async {
    final db = await _db;

    final total = await db.rawQuery('SELECT COUNT(*) as count FROM reminder_analytics');
    final actionTaken = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reminder_analytics WHERE action_taken = 1',
    );
    final snoozed = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reminder_analytics WHERE snooze_count > 0',
    );
    final avgEffectiveness = await db.rawQuery(
      'SELECT AVG(effectiveness_score) as avg FROM reminder_analytics WHERE effectiveness_score IS NOT NULL',
    );

    return {
      'totalReminders': total.first['count'] ?? 0,
      'actionTakenCount': actionTaken.first['count'] ?? 0,
      'snoozedCount': snoozed.first['count'] ?? 0,
      'avgEffectiveness': (avgEffectiveness.first['avg'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getEffectivenessByReminder() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT
        reminder_id,
        COUNT(*) as total,
        SUM(action_taken) as actions,
        AVG(effectiveness_score) as effectiveness
      FROM reminder_analytics
      GROUP BY reminder_id
      ORDER BY effectiveness DESC
    ''');
  }

  Future<double> getOverallEffectivenessRate() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT
        CAST(SUM(action_taken) AS REAL) / COUNT(*) * 100 as rate
      FROM reminder_analytics
    ''');
    return (result.first['rate'] as num?)?.toDouble() ?? 0.0;
  }
}
