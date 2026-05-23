import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationManagerScreen extends ConsumerStatefulWidget {
  const NotificationManagerScreen({super.key});

  @override
  ConsumerState<NotificationManagerScreen> createState() => _NotificationManagerScreenState();
}

class _NotificationManagerScreenState extends ConsumerState<NotificationManagerScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllRead(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': '全部'},
      {'key': 'reminder', 'label': '提醒'},
      {'key': 'system', 'label': '系统'},
      {'key': 'activity', 'label': '活动'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _getSampleNotifications();
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;
    
    IconData icon;
    Color color;
    switch (type) {
      case 'reminder':
        icon = Icons.notifications;
        color = Colors.blue;
        break;
      case 'system':
        icon = Icons.settings;
        color = Colors.grey;
        break;
      case 'activity':
        icon = Icons.event;
        color = Colors.green;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Dismissible(
      key: ValueKey(notification['id']),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Handle dismiss
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            notification['title'] as String,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification['body'] as String),
              const SizedBox(height: 4),
              Text(
                notification['time'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            setState(() {
              notification['isRead'] = true;
            });
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleNotifications() {
    return [
      {'id': 1, 'type': 'reminder', 'title': '会议提醒', 'body': '10分钟后有团队会议', 'time': '10 分钟前', 'isRead': false},
      {'id': 2, 'type': 'activity', 'title': '目标达成', 'body': '恭喜！您已连续打卡7天', 'time': '1 小时前', 'isRead': false},
      {'id': 3, 'type': 'system', 'title': '数据备份', 'body': '自动备份已完成', 'time': '2 小时前', 'isRead': true},
      {'id': 4, 'type': 'reminder', 'title': '喝水提醒', 'body': '该喝水了，保持健康！', 'time': '3 小时前', 'isRead': true},
      {'id': 5, 'type': 'activity', 'title': '周报生成', 'body': '您的周报已生成，点击查看', 'time': '昨天', 'isRead': true},
      {'id': 6, 'type': 'reminder', 'title': '运动提醒', 'body': '今天还没运动呢，开始吧！', 'time': '昨天', 'isRead': true},
    ];
  }

  void _markAllRead() {
    setState(() {
      // Mark all as read
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已全部标记为已读')),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通知设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('允许通知'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('声音'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('振动'),
              value: true,
              onChanged: (value) {},
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('免打扰时段'),
              subtitle: const Text('22:00 - 08:00'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}