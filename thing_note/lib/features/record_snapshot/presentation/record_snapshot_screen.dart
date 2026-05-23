import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_snapshot/data/record_snapshot_service.dart';
import '../domain/record_snapshot_models.dart';

/// 记录快照屏幕
class RecordSnapshotScreen extends ConsumerStatefulWidget {
  final int recordId;

  const RecordSnapshotScreen({
    super.key,
    required this.recordId,
  });

  @override
  ConsumerState<RecordSnapshotScreen> createState() => _RecordSnapshotScreenState();
}

class _RecordSnapshotScreenState extends ConsumerState<RecordSnapshotScreen> {
  List<RecordSnapshot> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(recordSnapshotServiceProvider);
      final snapshots = await service.getSnapshots(widget.recordId);

      setState(() {
        _snapshots = snapshots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录快照'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _snapshots.isEmpty
              ? _buildEmptyState()
              : _buildSnapshotList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无快照',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '快照会记录您每次编辑前的状态',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _snapshots.length,
      itemBuilder: (context, index) {
        final snapshot = _snapshots[index];
        return _buildSnapshotCard(snapshot);
      },
    );
  }

  Widget _buildSnapshotCard(RecordSnapshot snapshot) {
    final isExpired = snapshot.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired
              ? Theme.of(context).colorScheme.error.withOpacity(0.2)
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            isExpired ? Icons.history : Icons.save,
            color: isExpired
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          _formatDateTime(snapshot.createdAt),
          style: TextStyle(
            color: isExpired ? Theme.of(context).colorScheme.outline : null,
          ),
        ),
        subtitle: snapshot.note != null ? Text(snapshot.note!) : null,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 8),
                  Text('恢复'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('删除'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'restore') {
              _restoreSnapshot(snapshot);
            } else if (value == 'delete') {
              _deleteSnapshot(snapshot);
            }
          },
        ),
      ),
    );
  }

  Future<void> _restoreSnapshot(RecordSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复快照'),
        content: const Text('确定要恢复这个快照吗？当前内容将被覆盖。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(recordSnapshotServiceProvider);
      await service.restoreSnapshot(snapshot.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('快照已恢复')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteSnapshot(RecordSnapshot snapshot) async {
    try {
      final service = ref.read(recordSnapshotServiceProvider);
      await service.deleteSnapshot(snapshot.id);
      _loadSnapshots();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('快照已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';

    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}