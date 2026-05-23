import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/backup_models.dart';

/// 智能备份恢复屏幕
class SmartBackupScreen extends ConsumerWidget {
  const SmartBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(smartBackupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能备份'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => _showCreateBackupDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 配置卡片
          Consumer(
            builder: (context, ref, _) {
              final config = ref.watch(backupConfigProvider);
              return Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('自动备份'),
                      subtitle: const Text('按计划自动备份数据'),
                      value: config.autoBackup,
                      onChanged: (value) {
                        ref.read(backupConfigProvider.notifier).updateConfig(BackupConfig(autoBackup: value));
                      },
                    ),
                    if (config.autoBackup)
                      ListTile(
                        title: const Text('备份频率'),
                        subtitle: Text('每${config.frequency}'),
                        trailing: DropdownButton<String>(
                          value: config.frequency,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('每天')),
                            DropdownMenuItem(value: 'weekly', child: Text('每周')),
                            DropdownMenuItem(value: 'monthly', child: Text('每月')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(backupConfigProvider.notifier).updateConfig(BackupConfig(autoBackup: true, frequency: value));
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // 备份列表
          Expanded(
            child: backupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (backups) => backups.isEmpty
                  ? const Center(child: Text('暂无备份'))
                  : ListView.builder(
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        return ListTile(
                          leading: Icon(backup.isEncrypted ? Icons.lock : Icons.backup, color: Colors.blue),
                          title: Text(backup.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${backup.recordCount} 条记录, ${backup.mediaCount} 个媒体文件'),
                              Text('大小: ${backup.formattedSize}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore),
                                onPressed: () => _confirmRestore(context, ref, backup),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建备份'),
        content: const Text('确定要创建新的备份吗？这可能需要一些时间。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(smartBackupProvider.notifier).createBackup();
            },
            child: const Text('开始备份'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref, BackupEntry backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: Text('确定要恢复 "${backup.name}" 吗？这将覆盖当前数据。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(smartBackupProvider.notifier).restoreBackup(backup.id);
            },
            child: const Text('恢复', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}