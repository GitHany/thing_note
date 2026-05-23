import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/batch_archive/data/batch_archive_provider.dart';

class BatchArchiveScreen extends ConsumerStatefulWidget {
  const BatchArchiveScreen({super.key});

  @override
  ConsumerState<BatchArchiveScreen> createState() => _BatchArchiveScreenState();
}

class _BatchArchiveScreenState extends ConsumerState<BatchArchiveScreen> {
  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(archiveConfigProvider);
    final statsAsync = ref.watch(archiveStatsProvider);
    final jobsAsync = ref.watch(archiveJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('批量归档'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showConfigDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            statsAsync.when(
              data: (stats) => _buildStatsCard(context, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            
            // Config Card
            configAsync.when(
              data: (config) => _buildConfigCard(context, config),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            
            // Archive Jobs History
            Text(
              '归档历史',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            jobsAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _buildEmptyState(context);
                }
                return Column(
                  children: jobs.take(10).map((job) => _buildJobCard(context, job)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, ArchiveStats stats) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '归档统计',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  context,
                  '活跃记录',
                  stats.activeCount.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  '已归档',
                  stats.archivedCount.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  '释放空间',
                  stats.formattedStorage,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('归档率: '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: stats.archivePercent / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${stats.archivePercent.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, ArchiveConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '归档设置',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Switch(
                  value: config.autoArchiveEnabled,
                  onChanged: (value) {
                    // Update config
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConfigRow(
              context,
              Icons.calendar_today,
              '自动归档',
              config.autoArchiveEnabled
                  ? '${config.autoArchiveAfterDays}天后'
                  : '已禁用',
            ),
            const SizedBox(height: 8),
            _buildConfigRow(
              context,
              Icons.layers,
              '批量大小',
              '${config.batchSize}条/次',
            ),
            const SizedBox(height: 8),
            _buildConfigRow(
              context,
              Icons.compress,
              '压缩媒体',
              config.compressMedia
                  ? '质量${config.compressionQuality}%'
                  : '已禁用',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          '归档一年前',
          Icons.history,
          () => _showArchiveDialog(context, '一年前的记录'),
        ),
        _buildActionButton(
          context,
          '归档无媒体',
          Icons.photo_size_select_large,
          () => _showArchiveDialog(context, '无媒体附件的记录'),
        ),
        _buildActionButton(
          context,
          '归档特定分类',
          Icons.category,
          () => _showArchiveDialog(context, '特定分类的记录'),
        ),
        _buildActionButton(
          context,
          '恢复归档',
          Icons.restore,
          () => _showRestoreDialog(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.archive,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无归档历史',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '执行归档操作后记录会显示在这里',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, ArchiveJob job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: job.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(job.icon, color: job.statusColor),
        ),
        title: Text(job.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(job.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${job.recordsAffected}条记录 · 释放${_formatBytes(job.storageFreed)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: job.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            job.status,
            style: TextStyle(fontSize: 10, color: job.statusColor),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)}GB';
    }
  }

  void _showConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ArchiveConfigDialog(),
    );
  }

  void _showArchiveDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('归档 $title'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('此操作将：'),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('把记录移至归档存储'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('释放存储空间'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('保留数据可查询'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              '归档后记录仍可通过筛选查看，不会删除任何数据。',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('开始归档 $title')),
              );
            },
            child: const Text('开始归档'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复归档'),
        content: const Text('选择要恢复的归档记录'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在恢复归档记录...')),
              );
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }
}

class ArchiveConfigDialog extends StatefulWidget {
  const ArchiveConfigDialog({super.key});

  @override
  State<ArchiveConfigDialog> createState() => _ArchiveConfigDialogState();
}

class _ArchiveConfigDialogState extends State<ArchiveConfigDialog> {
  bool _autoArchive = false;
  final int _archiveDays = 365;
  final int _batchSize = 100;
  bool _compressMedia = true;
  // ignore: unused_field
  final int _compressionQuality = 70;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('归档设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('自动归档'),
              value: _autoArchive,
              onChanged: (value) => setState(() => _autoArchive = value),
            ),
            ListTile(
              title: const Text('归档周期'),
              subtitle: Text('$_archiveDays 天'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show number picker
              },
            ),
            ListTile(
              title: const Text('批量大小'),
              subtitle: Text('$_batchSize 条/次'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show number picker
              },
            ),
            SwitchListTile(
              title: const Text('压缩媒体'),
              value: _compressMedia,
              onChanged: (value) => setState(() => _compressMedia = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设置已保存')),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}