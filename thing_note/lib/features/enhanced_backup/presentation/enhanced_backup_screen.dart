import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/enhanced_backup/data/backup_provider.dart';
import 'package:thing_note/features/enhanced_backup/domain/backup_config.dart';

class EnhancedBackupScreen extends ConsumerWidget {
  const EnhancedBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(backupListProvider);
    final statsAsync = ref.watch(backupStatsProvider);
    final schedulesAsync = ref.watch(backupScheduleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () => _showScheduleDialog(context, ref),
            tooltip: 'Backup Schedule',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            data: (stats) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Backups', stats.totalBackups.toString()),
                    _buildStatItem('Total Size', stats.formattedTotalSize),
                    _buildStatItem('Last Backup', stats.lastBackupDays == 0 ? 'Today' : '${stats.lastBackupDays}d ago'),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Schedules
          schedulesAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backup Schedules',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...schedules.map((schedule) {
                      return ListTile(
                        leading: Icon(
                          schedule.isEnabled ? Icons.check_circle : Icons.cancel,
                          color: schedule.isEnabled ? Colors.green : Colors.grey,
                        ),
                        title: Text(schedule.name),
                        subtitle: Text('${schedule.frequency} at ${schedule.timeOfDay ?? "N/A"}'),
                        trailing: Switch(
                          value: schedule.isEnabled,
                          onChanged: (value) {
                            ref.read(backupScheduleNotifierProvider.notifier).toggleEnabled(schedule.id!, value);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Backup list
          Expanded(
            child: backupsAsync.when(
              data: (backups) {
                if (backups.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.backup, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No backups yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Tap + to create a backup', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    return _buildBackupCard(context, ref, backup);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await ref.read(enhancedBackupNotifierProvider.notifier).createBackup();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Backup created: ${result.name}')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBackupCard(BuildContext context, WidgetRef ref, EnhancedBackupEntry backup) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backup.isEncrypted ? Colors.orange : Colors.blue,
          child: Icon(
            backup.isCompressed ? Icons.compress : Icons.folder,
            color: Colors.white,
          ),
        ),
        title: Text(backup.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(backup.createdAt)),
            Text(
              '${backup.formattedSize} • ${backup.recordCount} records • ${backup.mediaCount} media',
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                if (backup.isCompressed) _buildBadge(Icons.compress, 'Compressed'),
                if (backup.isEncrypted) _buildBadge(Icons.lock, 'Encrypted'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'restore', child: Text('Restore')),
            const PopupMenuItem(value: 'share', child: Text('Share')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              ref.read(enhancedBackupNotifierProvider.notifier).deleteBackup(backup.id!);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 2),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Daily'),
              onTap: () {
                final schedule = BackupSchedule(
                  name: 'Daily Backup',
                  frequency: 'daily',
                  timeOfDay: '02:00',
                );
                ref.read(backupScheduleNotifierProvider.notifier).createSchedule(schedule);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Weekly'),
              onTap: () {
                final schedule = BackupSchedule(
                  name: 'Weekly Backup',
                  frequency: 'weekly',
                  timeOfDay: '02:00',
                  dayOfWeek: '0',
                );
                ref.read(backupScheduleNotifierProvider.notifier).createSchedule(schedule);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Monthly'),
              onTap: () {
                final schedule = BackupSchedule(
                  name: 'Monthly Backup',
                  frequency: 'monthly',
                  timeOfDay: '02:00',
                  dayOfMonth: '1',
                );
                ref.read(backupScheduleNotifierProvider.notifier).createSchedule(schedule);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}