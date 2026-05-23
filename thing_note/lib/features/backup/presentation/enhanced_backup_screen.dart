import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/backup/presentation/providers/backup_provider.dart';
import 'package:thing_note/features/backup/domain/backup_entry.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class EnhancedBackupScreen extends ConsumerWidget {
  const EnhancedBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(backupListProvider);
    final backupState = ref.watch(backupOperationProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enhancedBackup),
        actions: [
          if (backupState.isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'create':
                    ref.read(backupOperationProvider.notifier).createBackup();
                    break;
                  case 'settings':
                    _showBackupSettings(context, ref);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'create',
                  child: Row(
                    children: [
                      const Icon(Icons.backup),
                      const SizedBox(width: 8),
                      Text(l10n.createBackup),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 8),
                      Text(l10n.backupSettings),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          if (backupState.statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: backupState.error != null
                  ? Colors.red.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  if (backupState.isProcessing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (backupState.error != null)
                    const Icon(Icons.error, color: Colors.red, size: 16)
                  else
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      backupState.statusMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (backupState.progress != null)
                    Text(
                      '${(backupState.progress! * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),

          // 备份列表
          Expanded(
            child: backupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(l10n.loadFailed(e.toString())),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(backupListProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (backups) {
                if (backups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.backup,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.noBackupsFound,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createFirstBackupDesc,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(backupOperationProvider.notifier).createBackup(),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.createFirstBackup),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    return _BackupCard(
                      backup: backup,
                      onRestore: () => _showRestoreDialog(context, ref, backup),
                      onDelete: () => _confirmDelete(context, ref, backup),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupSettings(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final configAsync = ref.watch(backupConfigProvider);

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.backupSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                configAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text(l10n.loadFailed('Error')),
                  data: (config) => Column(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.autoBackup),
                        subtitle: Text(l10n.autoBackupDesc),
                        value: config.autoBackupEnabled,
                        onChanged: (value) {
                          // 保存配置
                        },
                      ),
                      ListTile(
                        title: Text(l10n.maxBackups),
                        subtitle: Text('${config.maxBackupsToKeep}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // 选择保留数量
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref, BackupEntry backup) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreWarning),
            const SizedBox(height: 16),
            Text(
              '${backup.fileName}\n${backup.formattedSize}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(backupOperationProvider.notifier).restoreBackup(
                    backup.id,
                    merge: false,
                  );
            },
            child: Text(l10n.restoreReplace),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(backupOperationProvider.notifier).restoreBackup(
                    backup.id,
                    merge: true,
                  );
            },
            child: Text(l10n.restoreMerge),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BackupEntry backup) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBackup),
        content: Text(l10n.deleteConfirmation(backup.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(backupOperationProvider.notifier).deleteBackup(backup.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final BackupEntry backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupCard({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: backup.isAutoBackup
                        ? Colors.blue.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    backup.isAutoBackup ? Icons.bolt : Icons.create,
                    color: backup.isAutoBackup ? Colors.blue : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backup.fileName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(backup.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'restore':
                        onRestore();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'restore',
                      child: Row(
                        children: [
                          const Icon(Icons.restore),
                          const SizedBox(width: 8),
                          Text(l10n.restore),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.storage,
                  label: backup.formattedSize,
                ),
                const SizedBox(width: 12),
                if (backup.isAutoBackup)
                  _InfoChip(
                    icon: Icons.auto_mode,
                    label: l10n.auto,
                    color: Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.outline).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}