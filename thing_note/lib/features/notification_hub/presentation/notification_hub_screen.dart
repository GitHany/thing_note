import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class NotificationHubScreen extends ConsumerStatefulWidget {
  const NotificationHubScreen({super.key});

  @override
  ConsumerState<NotificationHubScreen> createState() =>
      _NotificationHubScreenState();
}

class _NotificationHubScreenState
    extends ConsumerState<NotificationHubScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _reminderNotifications = true;
  bool _weeklyDigest = true;
  bool _marketingEmails = false;

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      title: '记录提醒',
      subtitle: '您有一个待处理的任务',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      type: _NotificationType.reminder,
    ),
    _NotificationItem(
      title: '备份完成',
      subtitle: '您的数据已成功备份到云端',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      type: _NotificationType.system,
    ),
    _NotificationItem(
      title: '周报摘要',
      subtitle: '本周您记录了 23 条事件',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: _NotificationType.report,
    ),
    _NotificationItem(
      title: '系统更新',
      subtitle: 'ThingNote v0.0.22 现已可用',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: _NotificationType.update,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationHub),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Notification settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.notificationSettings,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.pushNotifications),
                  secondary: const Icon(Icons.notifications),
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.emailNotifications),
                  secondary: const Icon(Icons.email),
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.reminderNotifications),
                  secondary: const Icon(Icons.alarm),
                  value: _reminderNotifications,
                  onChanged: (value) =>
                      setState(() => _reminderNotifications = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.weeklyDigest),
                  secondary: const Icon(Icons.weekend),
                  value: _weeklyDigest,
                  onChanged: (value) => setState(() => _weeklyDigest = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.marketingEmails),
                  secondary: const Icon(Icons.campaign),
                  value: _marketingEmails,
                  onChanged: (value) =>
                      setState(() => _marketingEmails = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification history
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentNotifications,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {},
                child: Text(AppLocalizations.of(context)!.clearAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_notifications.map((n) => _buildNotificationItem(n))),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(_NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openNotification(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                notification.isRead ? null : FontWeight.bold,
                          ),
                    ),
                    Text(
                      notification.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      _formatTime(notification.time),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(_NotificationType type) {
    switch (type) {
      case _NotificationType.reminder:
        return Icons.alarm;
      case _NotificationType.system:
        return Icons.settings;
      case _NotificationType.report:
        return Icons.analytics;
      case _NotificationType.update:
        return Icons.system_update;
      case _NotificationType.marketing:
        return Icons.campaign;
    }
  }

  Color _getTypeColor(_NotificationType type) {
    switch (type) {
      case _NotificationType.reminder:
        return Colors.orange;
      case _NotificationType.system:
        return Colors.grey;
      case _NotificationType.report:
        return Colors.blue;
      case _NotificationType.update:
        return Colors.green;
      case _NotificationType.marketing:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _openNotification(_NotificationItem notification) {
    setState(() => notification.isRead = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开: ${notification.title}')),
    );
  }
}

enum _NotificationType { reminder, system, report, update, marketing }

class _NotificationItem {
  final String title;
  final String subtitle;
  final DateTime time;
  bool isRead;
  final _NotificationType type;

  _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
    required this.type,
  });
}