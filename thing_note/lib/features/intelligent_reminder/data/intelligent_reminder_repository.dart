import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/intelligent_reminder/domain/intelligent_reminder.dart';

class IntelligentReminderRepository {
  final Ref _ref;

  IntelligentReminderRepository(this._ref);

  Future<List<IntelligentReminder>> getAllReminders() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'intelligent_reminders',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => IntelligentReminder.fromMap(e)).toList();
  }

  Future<List<IntelligentReminder>> getEnabledReminders() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'intelligent_reminders',
      where: 'is_enabled = 1',
      orderBy: 'effectiveness_score DESC',
    );
    return result.map((e) => IntelligentReminder.fromMap(e)).toList();
  }

  Future<List<IntelligentReminder>> getRemindersByTriggerType(String type) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'intelligent_reminders',
      where: 'trigger_type = ? AND is_enabled = 1',
      whereArgs: [type],
      orderBy: 'effectiveness_score DESC',
    );
    return result.map((e) => IntelligentReminder.fromMap(e)).toList();
  }

  Future<int> insertReminder(IntelligentReminder reminder) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('intelligent_reminders', reminder.toMap()..remove('id'));
  }

  Future<int> updateReminder(IntelligentReminder reminder) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'intelligent_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('intelligent_reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleEnabled(int id, bool isEnabled) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'intelligent_reminders',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> recordTrigger(int id) async {
    final db = await _ref.read(databaseProvider.future);
    await db.rawUpdate(
      'UPDATE intelligent_reminders SET triggered_count = triggered_count + 1, last_triggered = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
    return 1;
  }

  Future<void> updateEffectiveness(int id) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'intelligent_reminders',
      columns: ['triggered_count', 'last_triggered'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return;

    final row = result.first;
    final triggeredCount = row['triggered_count'] as int;

    // Calculate effectiveness based on trigger count
    // More triggers = higher effectiveness
    final effectiveness = (triggeredCount / 100).clamp(0.0, 1.0);

    await db.update(
      'intelligent_reminders',
      {'effectiveness_score': effectiveness},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<IntelligentReminder>> suggestReminders() async {
    final db = await _ref.read(databaseProvider.future);

    // Analyze user patterns and suggest new reminders
    final suggestions = <IntelligentReminder>[];

    // Check if user often forgets to record
    final recentRecords = await db.query(
      'episode_records',
      orderBy: 'occurred_at DESC',
      limit: 30,
    );

    if (recentRecords.length >= 7) {
      // User has 7+ days of records
      suggestions.add(IntelligentReminder(
        title: '每日记录提醒',
        triggerType: 'time',
        triggerConfig: jsonEncode({'hour': 21, 'minute': 0}),
        actionType: 'notification',
        actionConfig: jsonEncode({'message': '今天记录了吗？'}),
        createdAt: DateTime.now(),
      ));
    }

    return suggestions;
  }
}