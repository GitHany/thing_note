import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Smart Notification State
enum NotificationPriority { low, medium, high, urgent }

class SmartNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final NotificationPriority priority;
  final String? category;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  SmartNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.priority = NotificationPriority.medium,
    this.category,
    this.isRead = false,
    this.metadata,
  });

  SmartNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledAt,
    NotificationPriority? priority,
    String? category,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return SmartNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Smart Notifications Provider
final smartNotificationsProvider = StateNotifierProvider<SmartNotificationsNotifier, List<SmartNotificationItem>>((ref) {
  return SmartNotificationsNotifier();
});

class SmartNotificationsNotifier extends StateNotifier<List<SmartNotificationItem>> {
  SmartNotificationsNotifier() : super([
    SmartNotificationItem(
      id: '1',
      title: '记录提醒',
      body: '您有 3 条记录待整理',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      priority: NotificationPriority.medium,
      category: '提醒',
    ),
    SmartNotificationItem(
      id: '2',
      title: '数据备份',
      body: '上次备份已超过 7 天，建议立即备份',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      priority: NotificationPriority.high,
      category: '数据',
    ),
    SmartNotificationItem(
      id: '3',
      title: '周报生成',
      body: '您的周报已准备就绪',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      priority: NotificationPriority.low,
      category: '报告',
    ),
  ]);

  void addNotification(SmartNotificationItem notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

// Notification Settings
final notificationSettingsProvider = StateProvider<NotificationSettings>((ref) {
  return NotificationSettings(
    enabled: true,
    sound: true,
    vibration: true,
    badge: true,
    smartGrouping: true,
    quietHoursEnabled: false,
    quietHoursStart: '22:00',
    quietHoursEnd: '08:00',
  );
});

class NotificationSettings {
  final bool enabled;
  final bool sound;
  final bool vibration;
  final bool badge;
  final bool smartGrouping;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  NotificationSettings({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
    this.badge = true,
    this.smartGrouping = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? sound,
    bool? vibration,
    bool? badge,
    bool? smartGrouping,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      badge: badge ?? this.badge,
      smartGrouping: smartGrouping ?? this.smartGrouping,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

class SmartNotificationsScreen extends ConsumerWidget {
  const SmartNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(smartNotificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能通知'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(smartNotificationsProvider.notifier).markAllAsRead();
              },
              child: const Text('全部已读'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildNotificationStats(context, notifications),
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState(context)
                : _buildNotificationList(context, ref, notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStats(BuildContext context, List<SmartNotificationItem> notifications) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final urgentCount = notifications.where((n) => n.priority == NotificationPriority.urgent && !n.isRead).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              '未读',
              unreadCount.toString(),
              Icons.mark_email_unread,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              '紧急',
              urgentCount.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              '总计',
              notifications.length.toString(),
              Icons.notifications,
              Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    List<SmartNotificationItem> notifications,
  ) {
    // Group by date
    final grouped = <String, List<SmartNotificationItem>>{};
    for (final notification in notifications) {
      final dateKey = _formatDateKey(notification.scheduledAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final items = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...items.map((notification) {
              return _buildNotificationCard(context, ref, notification);
            }),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    SmartNotificationItem notification,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          ref.read(smartNotificationsProvider.notifier).markAsRead(notification.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _getPriorityColor(notification.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead ? null : FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (notification.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              notification.category!,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          _formatTime(notification.scheduledAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  ref.read(smartNotificationsProvider.notifier).removeNotification(notification.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无通知',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '所有通知都已处理',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final settings = ref.read(notificationSettingsProvider);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '通知设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用通知'),
                  value: settings.enabled,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).state =
                        settings.copyWith(enabled: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('声音'),
                  value: settings.sound,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).state =
                        settings.copyWith(sound: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('振动'),
                  value: settings.vibration,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).state =
                        settings.copyWith(vibration: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('角标'),
                  value: settings.badge,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).state =
                        settings.copyWith(badge: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('智能分组'),
                  subtitle: const Text('按类型和时间分组通知'),
                  value: settings.smartGrouping,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).state =
                        settings.copyWith(smartGrouping: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('勿扰模式'),
                  value: settings.quietHoursEnabled,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).state =
                        settings.copyWith(quietHoursEnabled: value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('保存设置'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
