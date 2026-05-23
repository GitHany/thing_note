import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/cloud_sync/data/cloud_sync_repository.dart';
import 'package:thing_note/features/cloud_sync/domain/cloud_sync_queue.dart';

final cloudSyncRepoProvider = Provider((ref) => CloudSyncRepository(ref));

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  List<CloudSyncQueue> _pendingItems = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(cloudSyncRepoProvider);
    _pendingItems = await repo.getPendingItems();
    _stats = await repo.getQueueStats();
    setState(() => _isLoading = false);
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    // In production, would initiate actual sync
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSyncing = false);
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同步完成！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云同步'),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncNow,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSyncStatus(),
                  const SizedBox(height: 16),
                  _buildPendingItems(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatus() {
    final pending = _stats['pending'] ?? 0;
    final syncing = _stats['syncing'] ?? 0;
    final failed = _stats['failed'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.pending,
                  value: pending,
                  label: '待同步',
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.sync,
                  value: syncing,
                  label: '同步中',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.error_outline,
                  value: failed,
                  label: '失败',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? '同步中...' : '立即同步'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItems() {
    if (_pendingItems.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 8),
            Text('所有数据已同步', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('待同步项目', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingItems.length,
              itemBuilder: (context, index) {
                final item = _pendingItems[index];
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text('${item.entityType} #${item.entityId}'),
                  subtitle: Text(item.action),
                  trailing: Text(
                    item.status,
                    style: TextStyle(
                      color: item.status == 'failed' ? Colors.red : Colors.orange,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }
}