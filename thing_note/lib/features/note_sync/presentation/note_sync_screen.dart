import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/note_sync/data/note_sync_repository.dart';

class NoteSyncScreen extends ConsumerWidget {
  const NoteSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(noteSyncQueueProvider);
    final historyAsync = ref.watch(noteSyncHistoryProvider);
    final stats = ref.watch(syncStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记同步'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncNow(context, ref),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const TabBar(
                tabs: [
                  Tab(text: '同步队列'),
                  Tab(text: '同步历史'),
                ],
              ),
            ),
            _buildSyncStatus(stats),
            Expanded(
              child: TabBarView(
                children: [
                  _buildQueueTab(queueAsync, ref),
                  _buildHistoryTab(historyAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(Map<String, dynamic> stats) {
    final pending = stats['pending'] as int;
    final failed = stats['failed'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusCard(
            icon: Icons.pending_actions,
            label: '待同步',
            value: '$pending',
            color: Colors.blue,
          ),
          _StatusCard(
            icon: Icons.error_outline,
            label: '失败',
            value: '$failed',
            color: Colors.red,
          ),
          _StatusCard(
            icon: Icons.check_circle_outline,
            label: '状态',
            value: pending == 0 && failed == 0 ? '正常' : '异常',
            color: pending == 0 && failed == 0 ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTab(AsyncValue<List<NoteSyncRecord>> queueAsync, WidgetRef ref) {
    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_done, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('同步队列为空', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('所有数据已同步完成', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _SyncQueueCard(
              record: record,
              onRetry: () => ref.read(noteSyncQueueProvider.notifier).retrySync(record.id!),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<NoteSyncHistory>> historyAsync) {
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (history) {
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无同步历史', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return _SyncHistoryCard(history: item);
          },
        );
      },
    );
  }

  void _syncNow(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始同步...')),
    );
    // Trigger sync
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SyncQueueCard extends StatelessWidget {
  final NoteSyncRecord record;
  final VoidCallback onRetry;

  const _SyncQueueCard({required this.record, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isFailed = record.status == 'failed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isFailed ? Icons.error : Icons.pending,
          color: isFailed ? Colors.red : Colors.orange,
        ),
        title: Text('笔记 #${record.noteId}'),
        subtitle: Text('${record.action} • ${record.createdAt}'),
        trailing: isFailed
            ? IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: onRetry,
              )
            : const Icon(Icons.sync, color: Colors.grey),
      ),
    );
  }
}

class _SyncHistoryCard extends StatelessWidget {
  final NoteSyncHistory history;

  const _SyncHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final isSuccess = history.status == 'success';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        title: Text('笔记 #${history.noteId}'),
        subtitle: Text('${history.action} • ${_formatDate(history.syncedAt)}'),
        trailing: Text(
          history.status,
          style: TextStyle(color: isSuccess ? Colors.green : Colors.red, fontSize: 12),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}