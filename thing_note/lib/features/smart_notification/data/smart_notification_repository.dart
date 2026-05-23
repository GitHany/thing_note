import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/smart_notification/domain/smart_notification.dart';
import 'package:thing_note/core/database/database_provider.dart';

final smartNotificationRepositoryProvider = Provider((ref) => SmartNotificationRepository(ref));

class SmartNotificationRepository {
  final Ref _ref;

  SmartNotificationRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<List<SmartNotification>> getAllNotifications() async {
    final db = await _db;
    final results = await db.query('smart_notifications', orderBy: 'created_at DESC');
    return results.map((e) => SmartNotification.fromMap(e)).toList();
  }

  Future<List<SmartNotification>> getEnabledNotifications() async {
    final db = await _db;
    final results = await db.query(
      'smart_notifications',
      where: 'is_enabled = 1',
      orderBy: 'created_at DESC',
    );
    return results.map((e) => SmartNotification.fromMap(e)).toList();
  }

  Future<int> insertNotification(SmartNotification notification) async {
    final db = await _db;
    return await db.insert('smart_notifications', notification.toMap());
  }

  Future<int> updateNotification(SmartNotification notification) async {
    final db = await _db;
    return await db.update(
      'smart_notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await _db;
    return await db.delete(
      'smart_notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleNotification(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE smart_notifications SET is_enabled = CASE WHEN is_enabled = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  Future<void> markAsTriggered(int id) async {
    final db = await _db;
    await db.update(
      'smart_notifications',
      {'last_triggered': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get notification suggestions based on user behavior
  Future<List<SmartNotification>> getSuggestions() async {
    final db = await _db;
    
    // Check for incomplete habits
    final incompleteHabits = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_streaks WHERE current_streak > 0
    ''');
    
    // Check for upcoming goal deadlines
    final upcomingGoals = await db.rawQuery('''
      SELECT COUNT(*) as count FROM goals 
      WHERE deadline IS NOT NULL AND deadline > date('now') AND deadline < date('now', '+7 days')
    ''');
    
    final suggestions = <SmartNotification>[];
    
    if ((incompleteHabits.first['count'] as int? ?? 0) > 0) {
      suggestions.add(SmartNotification(
        title: '习惯打卡提醒',
        body: '您有一些习惯还未打卡，记得今天完成哦！',
        type: 'suggestion',
        createdAt: DateTime.now(),
      ));
    }
    
    if ((upcomingGoals.first['count'] as int? ?? 0) > 0) {
      suggestions.add(SmartNotification(
        title: '目标截止提醒',
        body: '您有目标即将到期，请注意进度！',
        type: 'alert',
        createdAt: DateTime.now(),
      ));
    }
    
    return suggestions;
  }

  /// Initialize default notifications
  Future<void> initDefaultNotifications() async {
    final db = await _db;
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM smart_notifications'),
    );
    
    if (count != null && count > 0) return;

    final defaults = [
      SmartNotification(
        title: '每日记录提醒',
        body: '今天记得记录您的活动哦！',
        type: 'reminder',
        triggerConfig: '{"time": "20:00", "weekdays": [1,2,3,4,5,6,7]}',
        createdAt: DateTime.now(),
      ),
      SmartNotification(
        title: '每周回顾提醒',
        body: '是时候回顾一下本周的表现了！',
        type: 'summary',
        triggerConfig: '{"weekday": 7, "time": "18:00"}',
        createdAt: DateTime.now(),
      ),
    ];

    for (final notification in defaults) {
      await db.insert('smart_notifications', notification.toMap());
    }
  }
}