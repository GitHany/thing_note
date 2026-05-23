import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_models.dart';

/// 通知聚合面板屏幕
class NotificationAggregatorScreen extends ConsumerWidget {
  const NotificationAggregatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationAggregatorProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationAggregatorProvider.notifier).markAllAsRead(),
              child: const Text('全部已读'),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (notifications) => notifications.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无通知'),
                ],
              ))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: notification.color.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(notification.icon, color: notification.color),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(_formatTime(notification.createdAt), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: !notification.isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)) : null,
                    onTap: () {
                      if (!notification.isRead) {
                        ref.read(notificationAggregatorProvider.notifier).markAsRead(notification.id);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}