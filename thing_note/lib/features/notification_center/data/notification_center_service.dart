import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final notificationCenterProvider = Provider<NotificationCenterService>((ref) {
    final dbAsync = ref.watch(databaseProvider);
    return NotificationCenterService(dbAsync);
});

/// 通知消息模型
class NotificationMessage {
  final int? id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationMessage({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  NotificationMessage copyWith({
    int? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'data': data?.toString(),
    };
  }

  factory NotificationMessage.fromMap(Map<String, dynamic> map) {
    return NotificationMessage(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.info,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int?) == 1,
      data: map['data'] != null ? Map<String, dynamic>.from({}) : null,
    );
  }
}

enum NotificationType {
  info,
  reminder,
  achievement,
  suggestion,
  warning,
}

/// 通知中心服务
class NotificationCenterService {
  final AsyncValue<Database> _dbAsync;

  NotificationCenterService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> initTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        data TEXT
      )
    ''');
  }

  Future<int> addNotification(NotificationMessage notification) async {
    final db = await _db;
    return db.insert('notification_messages', notification.toMap());
  }

  Future<int> markAsRead(int id) async {
    final db = await _db;
    return db.update(
      'notification_messages',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAllAsRead() async {
    final db = await _db;
    return db.update(
      'notification_messages',
      {'is_read': 1},
      where: 'is_read = 0',
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await _db;
    return db.delete('notification_messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await _db;
    return db.delete('notification_messages');
  }

  Future<List<NotificationMessage>> getAllNotifications({int limit = 50}) async {
    final db = await _db;
    final maps = await db.query(
      'notification_messages',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => NotificationMessage.fromMap(m)).toList();
  }

  Future<int> getUnreadCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notification_messages WHERE is_read = 0',
    );
    return result.first['count'] as int? ?? 0;
  }

  /// 生成每日摘要通知
  Future<void> generateDailySummary() async {
    final db = await _db;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(duration_sec) as total_duration
      FROM episode_records
      WHERE occurred_at >= ?
    ''', [todayStart.toIso8601String()]);
    
    if (result.isEmpty) return;
    
    final count = result.first['count'] as int? ?? 0;
    final totalDuration = result.first['total_duration'] as int? ?? 0;
    
    if (count > 0) {
      final duration = Duration(seconds: totalDuration);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      await addNotification(NotificationMessage(
        title: '今日记录摘要',
        body: '今天你记录了 $count 条事件，总时长 ${hours > 0 ? "$hours小时" : ""}$minutes分钟',
        type: NotificationType.info,
        createdAt: now,
      ));
    }
  }

  /// 生成习惯提醒通知
  Future<void> generateHabitReminders() async {
    final db = await _db;
    
    final habits = await db.query('habits', where: 'last_completed_at IS NULL');
    
    for (final habit in habits) {
      await addNotification(NotificationMessage(
        title: '习惯提醒',
        body: '记得完成 "${habit['name']}" 习惯哦！',
        type: NotificationType.reminder,
        createdAt: DateTime.now(),
        data: {'habit_id': habit['id']},
      ));
    }
  }

  /// 生成目标进度通知
  Future<void> generateGoalNotifications() async {
    final db = await _db;
    
    final goals = await db.query(
      'goals',
      where: 'status = ? AND deadline IS NOT NULL',
      whereArgs: ['active'],
    );
    
    for (final goal in goals) {
      final deadline = DateTime.parse(goal['deadline'] as String);
      final daysLeft = deadline.difference(DateTime.now()).inDays;
      
      if (daysLeft == 1) {
        await addNotification(NotificationMessage(
          title: '目标截止提醒',
          body: '目标 "${goal['title']}" 明天截止！',
          type: NotificationType.warning,
          createdAt: DateTime.now(),
          data: {'goal_id': goal['id']},
        ));
      }
    }
  }
}

/// 通知中心状态
class NotificationCenterState {
  final List<NotificationMessage> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationCenterState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationCenterState copyWith({
    List<NotificationMessage>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationCenterState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationCenterNotifier extends StateNotifier<NotificationCenterState> {
  final NotificationCenterService _service;

  NotificationCenterNotifier(this._service) : super(const NotificationCenterState()) {
    _init();
  }

  Future<void> _init() async {
    await _service.initTable();
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final notifications = await _service.getAllNotifications();
      final unreadCount = await _service.getUnreadCount();
      state = NotificationCenterState(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(int id) async {
    await _service.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    await loadNotifications();
  }

  Future<void> deleteNotification(int id) async {
    await _service.deleteNotification(id);
    await loadNotifications();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    await loadNotifications();
  }
}

final notificationCenterStateProvider =
    StateNotifierProvider<NotificationCenterNotifier, NotificationCenterState>((ref) {
  final service = ref.watch(notificationCenterProvider);
  return NotificationCenterNotifier(service);
});