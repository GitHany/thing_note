import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/smart_notifications/domain/smart_notification_model.dart';

/// Repository for Smart Notifications data operations
class SmartNotificationsRepository {
  final Database db;

  SmartNotificationsRepository(this.db);

  /// Create a notification
  Future<int> createNotification(SmartNotification notification) async {
    return await db.insert('smart_notifications', notification.toMap());
  }

  /// Update a notification
  Future<int> updateNotification(SmartNotification notification) async {
    return await db.update(
      'smart_notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  /// Delete a notification
  Future<int> deleteNotification(int id) async {
    return await db.delete(
      'smart_notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all notifications
  Future<List<SmartNotification>> getAllNotifications() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_notifications',
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => SmartNotification.fromMap(map)).toList();
  }

  /// Get pending notifications
  Future<List<SmartNotification>> getPendingNotifications() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_notifications',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'priority DESC, scheduled_time ASC',
    );
    return maps.map((map) => SmartNotification.fromMap(map)).toList();
  }

  /// Get notifications due now
  Future<List<SmartNotification>> getNotificationsDueNow() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_notifications',
      where: 'status = ? AND scheduled_time <= ?',
      whereArgs: ['pending', now.toIso8601String()],
      orderBy: 'priority DESC',
    );
    return maps.map((map) => SmartNotification.fromMap(map)).toList();
  }

  /// Mark notification as sent
  Future<int> markAsSent(int id) async {
    return await db.update(
      'smart_notifications',
      {
        'status': 'sent',
        'sent_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark notification as opened
  Future<int> markAsOpened(int id) async {
    return await db.update(
      'smart_notifications',
      {
        'status': 'opened',
        'opened_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get notification by ID
  Future<SmartNotification?> getNotificationById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SmartNotification.fromMap(maps.first);
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM smart_notifications');
    final sent = await db.rawQuery(
      'SELECT COUNT(*) as count FROM smart_notifications WHERE status = ?',
      ['sent']
    );
    final opened = await db.rawQuery(
      'SELECT COUNT(*) as count FROM smart_notifications WHERE status = ?',
      ['opened']
    );
    final pending = await db.rawQuery(
      'SELECT COUNT(*) as count FROM smart_notifications WHERE status = ?',
      ['pending']
    );

    return {
      'total': (total.first['count'] as int?) ?? 0,
      'sent': (sent.first['count'] as int?) ?? 0,
      'opened': (opened.first['count'] as int?) ?? 0,
      'pending': (pending.first['count'] as int?) ?? 0,
    };
  }

  /// Clear old notifications
  Future<int> clearOldNotifications({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return await db.delete(
      'smart_notifications',
      where: 'created_at < ? AND status IN (?, ?)',
      whereArgs: [cutoffDate.toIso8601String(), 'sent', 'opened'],
    );
  }

  // ========== Configuration Operations ==========

  /// Get smart notification configuration
  Future<SmartNotificationConfig> getConfig() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_notification_config',
      limit: 1,
    );
    if (maps.isEmpty) {
      return SmartNotificationConfig();
    }
    return SmartNotificationConfig.fromMap(maps.first);
  }

  /// Save smart notification configuration
  Future<void> saveConfig(SmartNotificationConfig config) async {
    final existing = await db.query('smart_notification_config', limit: 1);
    
    if (existing.isEmpty) {
      await db.insert('smart_notification_config', config.toMap());
    } else {
      await db.update(
        'smart_notification_config',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }
}