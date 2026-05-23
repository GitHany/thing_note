import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通知项
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'reminder', 'system', 'habit', 'goal'
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.metadata,
  });

  IconData get icon {
    switch (type) {
      case 'reminder': return Icons.alarm;
      case 'system': return Icons.settings;
      case 'habit': return Icons.check_circle;
      case 'goal': return Icons.flag;
      default: return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'reminder': return Colors.orange;
      case 'system': return Colors.blue;
      case 'habit': return Colors.green;
      case 'goal': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

/// 通知聚合面板 Provider
final notificationAggregatorProvider = StateNotifierProvider<NotificationAggregatorNotifier, AsyncValue<List<NotificationItem>>>((ref) {
  return NotificationAggregatorNotifier();
});

class NotificationAggregatorNotifier extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  NotificationAggregatorNotifier() : super(const AsyncValue.loading());

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data([
        NotificationItem(id: '1', title: '习惯提醒', body: '该打卡了！', type: 'habit', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
        NotificationItem(id: '2', title: '目标截止', body: '目标将在明天截止', type: 'goal', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
        NotificationItem(id: '3', title: '系统更新', body: '新版本已发布', type: 'system', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    state.whenData((items) {
      state = AsyncValue.data(
        items.map((item) => item.id == id ? NotificationItem(id: item.id, title: item.title, body: item.body, type: item.type, createdAt: item.createdAt, isRead: true, actionRoute: item.actionRoute, metadata: item.metadata) : item).toList(),
      );
    });
  }

  Future<void> markAllAsRead() async {
    state.whenData((items) {
      state = AsyncValue.data(items.map((item) => NotificationItem(id: item.id, title: item.title, body: item.body, type: item.type, createdAt: item.createdAt, isRead: true, actionRoute: item.actionRoute, metadata: item.metadata)).toList());
    });
  }

  Future<void> deleteNotification(String id) async {
    state.whenData((items) {
      state = AsyncValue.data(items.where((item) => item.id != id).toList());
    });
  }
}

/// 未读数量
final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationAggregatorProvider);
  return notifications.whenData((items) => items.where((item) => !item.isRead).length).value ?? 0;
});