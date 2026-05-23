import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_notification/data/smart_notification_repository.dart';
import 'package:thing_note/features/smart_notification/domain/smart_notification.dart';

class SmartNotificationScreen extends ConsumerStatefulWidget {
  const SmartNotificationScreen({super.key});

  @override
  ConsumerState<SmartNotificationScreen> createState() => _SmartNotificationScreenState();
}

class _SmartNotificationScreenState extends ConsumerState<SmartNotificationScreen> {
  List<SmartNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final repo = ref.read(smartNotificationRepositoryProvider);
    await repo.initDefaultNotifications();
    _notifications = await repo.getAllNotifications();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能通知'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无通知设置'),
          const SizedBox(height: 8),
          Text(
            '创建智能通知以获得更好的提醒体验',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加通知'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationCard(
          notification: notification,
          onToggle: () => _toggleNotification(notification),
          onEdit: () => _showEditDialog(notification),
          onDelete: () => _deleteNotification(notification),
        );
      },
    );
  }

  Future<void> _toggleNotification(SmartNotification notification) async {
    final repo = ref.read(smartNotificationRepositoryProvider);
    await repo.toggleNotification(notification.id!);
    _loadNotifications();
  }

  void _showAddDialog() {
    _showFormDialog();
  }

  void _showEditDialog(SmartNotification notification) {
    _showFormDialog(notification: notification);
  }

  void _showFormDialog({SmartNotification? notification}) {
    final titleController = TextEditingController(text: notification?.title ?? '');
    final bodyController = TextEditingController(text: notification?.body ?? '');
    String selectedType = notification?.type ?? 'reminder';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(notification == null ? '添加通知' : '编辑通知'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '通知标题'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(labelText: '通知内容'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('通知类型'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('提醒'),
                      selected: selectedType == 'reminder',
                      onSelected: (s) => setDialogState(() => selectedType = 'reminder'),
                    ),
                    ChoiceChip(
                      label: const Text('建议'),
                      selected: selectedType == 'suggestion',
                      onSelected: (s) => setDialogState(() => selectedType = 'suggestion'),
                    ),
                    ChoiceChip(
                      label: const Text('摘要'),
                      selected: selectedType == 'summary',
                      onSelected: (s) => setDialogState(() => selectedType = 'summary'),
                    ),
                    ChoiceChip(
                      label: const Text('警报'),
                      selected: selectedType == 'alert',
                      onSelected: (s) => setDialogState(() => selectedType = 'alert'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final repo = ref.read(smartNotificationRepositoryProvider);
                final newNotification = SmartNotification(
                  id: notification?.id,
                  title: titleController.text.trim(),
                  body: bodyController.text.trim(),
                  type: selectedType,
                  triggerConfig: notification?.triggerConfig,
                  isEnabled: notification?.isEnabled ?? true,
                  createdAt: notification?.createdAt ?? DateTime.now(),
                );
                if (notification == null) {
                  await repo.insertNotification(newNotification);
                } else {
                  await repo.updateNotification(newNotification);
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadNotifications();
              },
              child: Text(notification == null ? '添加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotification(SmartNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此通知吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(smartNotificationRepositoryProvider);
      await repo.deleteNotification(notification.id!);
      _loadNotifications();
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final SmartNotification notification;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'reminder':
        return Icons.alarm;
      case 'suggestion':
        return Icons.lightbulb;
      case 'summary':
        return Icons.summarize;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case 'reminder':
        return Colors.blue;
      case 'suggestion':
        return Colors.amber;
      case 'summary':
        return Colors.green;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getTypeIcon(), color: _getTypeColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (notification.body != null && notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TypeChip(type: notification.type),
                      if (notification.lastTriggered != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '上次: ${_formatTime(notification.lastTriggered!)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: notification.isEnabled,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(ctx);
              onEdit();
            },
          ),
          ListTile(
            leading: Icon(
              notification.isEnabled ? Icons.toggle_off : Icons.toggle_on,
            ),
            title: Text(notification.isEnabled ? '禁用' : '启用'),
            onTap: () {
              Navigator.pop(ctx);
              onToggle();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('删除'),
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (type) {
      case 'reminder':
        label = '提醒';
        color = Colors.blue;
        break;
      case 'suggestion':
        label = '建议';
        color = Colors.amber;
        break;
      case 'summary':
        label = '摘要';
        color = Colors.green;
        break;
      case 'alert':
        label = '警报';
        color = Colors.red;
        break;
      default:
        label = type;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}