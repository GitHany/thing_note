import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/sync_status_dashboard/data/sync_status_service.dart';
import 'package:thing_note/features/sync_status_dashboard/domain/sync_status_models.dart';

class SyncStatusDashboardScreen extends ConsumerStatefulWidget {
  const SyncStatusDashboardScreen({super.key});

  @override
  ConsumerState<SyncStatusDashboardScreen> createState() => _SyncStatusDashboardScreenState();
}

class _SyncStatusDashboardScreenState extends ConsumerState<SyncStatusDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步状态面板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _triggerSync(context),
            tooltip: '手动同步',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(syncStatusProvider);
              ref.invalidate(syncQueueProvider);
            },
            tooltip: '刷新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: '队列'),
            Tab(text: '历史'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _QueueTab(),
          _HistoryTab(),
        ],
      ),
    );
  }

  void _triggerSync(BuildContext context) async {
    final service = ref.read(syncStatusServiceProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始同步...')),
    );

    await service.triggerSync();
    ref.invalidate(syncStatusProvider);
    ref.invalidate(syncQueueProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同步完成')),
      );
    }
  }
}

/// 概览标签页
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);

    return statusAsync.when(
      data: (status) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 连接状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: status.isConnected
                                ? Colors.green.withOpacity( 0.1)
                                : Colors.red.withOpacity( 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status.isConnected ? Icons.cloud_done : Icons.cloud_off,
                            color: status.isConnected ? Colors.green : Colors.red,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.isConnected ? '已连接' : '未连接',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                status.isSyncing ? '同步中...' : '上次同步: ${_formatTime(status.lastSyncTime)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (status.pendingCount > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('待同步: ${status.pendingCount} 项'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 快速操作
            const Text(
              '快速操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.sync,
                    label: '立即同步',
                    color: Colors.blue,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.cleaning_services,
                    label: '清理队列',
                    color: Colors.green,
                    onTap: () => _clearQueue(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.warning_amber,
                    label: '解决冲突',
                    color: Colors.orange,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.settings,
                    label: '同步设置',
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 存储统计
            const Text(
              '存储统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StorageRow(label: '记录数量', value: '1,234 条'),
                    Divider(),
                    _StorageRow(label: '附件大小', value: '256 MB'),
                    Divider(),
                    _StorageRow(label: '总大小', value: '320 MB'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '未知';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  void _clearQueue(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理队列'),
        content: const Text('确定要清理已完成的同步项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(syncStatusServiceProvider);
      await service.clearSyncedItems();
      ref.invalidate(syncQueueProvider);
      ref.invalidate(syncStatusProvider);
    }
  }
}

/// 队列标签页
class _QueueTab extends ConsumerWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(syncQueueProvider);

    return queueAsync.when(
      data: (queue) {
        if (queue.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('同步队列为空'),
                SizedBox(height: 8),
                Text('所有项目已同步完成', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: queue.length,
          itemBuilder: (context, index) {
            final item = queue[index];
            return _QueueItemCard(item: item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 历史标签页
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(syncStatusServiceProvider);

    return FutureBuilder<List<SyncHistoryItem>>(
      future: service.getSyncHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无同步历史'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  item.success ? Icons.check_circle : Icons.error,
                  color: item.success ? Colors.green : Colors.red,
                ),
                title: Text(_getActionLabel(item.action)),
                subtitle: Text(_formatDate(item.syncedAt)),
                trailing: item.success
                    ? null
                    : item.error != null
                        ? Tooltip(
                            message: item.error!,
                            child: const Icon(Icons.info_outline, color: Colors.orange),
                          )
                        : null,
              ),
            );
          },
        );
      },
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'create':
        return '创建记录';
      case 'update':
        return '更新记录';
      case 'delete':
        return '删除记录';
      case 'resolve_conflict':
        return '解决冲突';
      default:
        return action;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 快速操作卡片
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 存储统计行
class _StorageRow extends StatelessWidget {
  final String label;
  final String value;

  const _StorageRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// 队列项卡片
class _QueueItemCard extends StatelessWidget {
  final SyncQueueItem item;

  const _QueueItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getStatusIcon(item.status),
        title: Text('记录 #${item.recordId}'),
        subtitle: Text(_getActionLabel(item.action)),
        trailing: _getStatusChip(item.status),
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.schedule, color: Colors.grey);
      case 'syncing':
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case 'synced':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'failed':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  Widget _getStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.grey;
        label = '等待';
      case 'syncing':
        color = Colors.blue;
        label = '同步中';
      case 'synced':
        color = Colors.green;
        label = '已完成';
      case 'failed':
        color = Colors.red;
        label = '失败';
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'create':
        return '创建';
      case 'update':
        return '更新';
      case 'delete':
        return '删除';
      default:
        return action;
    }
  }
}