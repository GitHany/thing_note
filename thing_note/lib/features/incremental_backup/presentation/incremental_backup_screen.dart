import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IncrementalBackupScreen extends ConsumerStatefulWidget {
  const IncrementalBackupScreen({super.key});

  @override
  ConsumerState<IncrementalBackupScreen> createState() => _IncrementalBackupScreenState();
}

class _IncrementalBackupScreenState extends ConsumerState<IncrementalBackupScreen> {
  bool _isBackingUp = false;
  double _backupProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增量备份系统'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildBackupStatus(),
          Expanded(
            child: _buildBackupHistory(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBackingUp ? null : _startBackup,
        icon: Icon(_isBackingUp ? Icons.hourglass_empty : Icons.backup),
        label: Text(_isBackingUp ? '备份中...' : '开始备份'),
      ),
    );
  }

  Widget _buildBackupStatus() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '上次备份',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _showBackupSettings(context);
                  },
                  child: const Text('设置'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('2026-05-21 10:30:00', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(Icons.storage, '1.2 GB'),
                const SizedBox(width: 8),
                _buildStatusChip(Icons.description, '1,234 条记录'),
                const SizedBox(width: 8),
                _buildStatusChip(Icons.photo, '89 张照片'),
              ],
            ),
            if (_isBackingUp) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _backupProgress),
              const SizedBox(height: 8),
              Text('备份进度: ${(_backupProgress * 100).toInt()}%'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildBackupHistory() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '备份历史',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildBackupItem('2026-05-21 10:30', '增量备份', '1.2 GB', true),
        _buildBackupItem('2026-05-20 22:00', '增量备份', '856 MB', true),
        _buildBackupItem('2026-05-19 08:00', '全量备份', '2.1 GB', true),
        _buildBackupItem('2026-05-18 10:30', '增量备份', '923 MB', true),
        _buildBackupItem('2026-05-17 22:00', '增量备份', '789 MB', false),
      ],
    );
  }

  Widget _buildBackupItem(String time, String type, String size, bool isComplete) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          isComplete ? Icons.check_circle : Icons.error_outline,
          color: isComplete ? Colors.green : Colors.red,
        ),
        title: Text('$time - $type'),
        subtitle: Text(size),
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
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (isComplete) {
            _showRestoreDialog(context);
          }
        },
      ),
    );
  }

  void _startBackup() async {
    setState(() {
      _isBackingUp = true;
      _backupProgress = 0.0;
    });

    // Simulate backup progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _backupProgress = i / 100;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isBackingUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份完成')),
      );
    }
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text('确定要从备份恢复数据吗？当前数据将自动备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start restore
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showBackupSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '备份设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('自动备份'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('保留备份数量'),
              trailing: const Text('10'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.compress),
              title: const Text('压缩备份'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('加密备份'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}