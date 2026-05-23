import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/sync/presentation/providers/sync_provider.dart';
import 'package:thing_note/features/sync/domain/sync_service.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSyncTimeAsync = ref.watch(lastSyncTimeProvider);
    final syncConfigAsync = ref.watch(syncConfigProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 同步状态卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(syncStatus),
                        color: _getStatusColor(syncStatus),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.syncStatus,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _getStatusText(syncStatus, l10n),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (syncStatus == SyncStatus.idle || syncStatus == SyncStatus.failed)
                        FilledButton.icon(
                          onPressed: () => ref.read(syncStatusProvider.notifier).sync(),
                          icon: const Icon(Icons.sync),
                          label: Text(l10n.syncNow),
                        ),
                      if (syncStatus == SyncStatus.syncing)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 最后同步时间
          lastSyncTimeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (lastTime) {
              if (lastTime == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l10n.lastSyncTime),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(lastTime)),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 同步配置
          syncConfigAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (config) => Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.sync),
                    title: Text(l10n.autoSync),
                    subtitle: Text(l10n.autoSyncDesc),
                    value: config.autoSyncEnabled,
                    onChanged: (value) async {
                      final repo = ref.read(syncRepositoryProvider);
                      await repo.saveSyncConfig(config.copyWith(autoSyncEnabled: value));
                      ref.invalidate(syncConfigProvider);
                    },
                  ),
                  if (config.autoSyncEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: Text(l10n.syncInterval),
                      subtitle: Text('${config.autoSyncInterval.inMinutes} ${l10n.minutes}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showIntervalPicker(context, ref, config),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 同步方向
          syncConfigAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (config) => Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.syncDirection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  RadioListTile<SyncDirection>(
                    title: Text(l10n.uploadOnly),
                    subtitle: Text(l10n.uploadOnlyDesc),
                    value: SyncDirection.upload,
                    groupValue: config.preferredDirection,
                    onChanged: (value) async {
                      if (value == null) return;
                      final repo = ref.read(syncRepositoryProvider);
                      await repo.saveSyncConfig(config.copyWith(preferredDirection: value));
                      ref.invalidate(syncConfigProvider);
                    },
                  ),
                  RadioListTile<SyncDirection>(
                    title: Text(l10n.downloadOnly),
                    subtitle: Text(l10n.downloadOnlyDesc),
                    value: SyncDirection.download,
                    groupValue: config.preferredDirection,
                    onChanged: (value) async {
                      if (value == null) return;
                      final repo = ref.read(syncRepositoryProvider);
                      await repo.saveSyncConfig(config.copyWith(preferredDirection: value));
                      ref.invalidate(syncConfigProvider);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 连接状态
          Card(
            child: ListTile(
              leading: Icon(
                Icons.cloud_done,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.larkConnection),
              subtitle: Text(l10n.larkConnected),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // 刷新连接状态
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icons.cloud_queue;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.failed:
        return Icons.cloud_off;
    }
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText(SyncStatus status, AppLocalizations l10n) {
    switch (status) {
      case SyncStatus.idle:
        return l10n.syncIdle;
      case SyncStatus.syncing:
        return l10n.syncInProgress;
      case SyncStatus.success:
        return l10n.syncSuccess;
      case SyncStatus.failed:
        return l10n.syncFailed;
    }
  }

  void _showIntervalPicker(BuildContext context, WidgetRef ref, SyncConfig config) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectInterval),
        children: [15, 30, 60, 120, 240].map((minutes) {
          return SimpleDialogOption(
            onPressed: () async {
              final repo = ref.read(syncRepositoryProvider);
              await repo.saveSyncConfig(config.copyWith(
                autoSyncInterval: Duration(minutes: minutes),
              ));
              ref.invalidate(syncConfigProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('$minutes ${l10n.minutes}'),
          );
        }).toList(),
      ),
    );
  }
}