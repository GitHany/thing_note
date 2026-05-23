import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 提醒管理屏幕 - 批量管理所有记录的提醒
class ReminderManagementScreen extends ConsumerStatefulWidget {
  const ReminderManagementScreen({super.key});

  @override
  ConsumerState<ReminderManagementScreen> createState() => _ReminderManagementScreenState();
}

class _ReminderManagementScreenState extends ConsumerState<ReminderManagementScreen> {
  bool _showActiveOnly = true;

  @override
  Widget build(BuildContext context) {
    final reminderRecordsAsync = ref.watch(reminderRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reminderManagement),
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.visibility_off : Icons.visibility),
            tooltip: _showActiveOnly ? '显示所有' : '仅显示有提醒的',
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
            },
          ),
        ],
      ),
      body: _showActiveOnly
          ? reminderRecordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (records) => _buildReminderList(records),
            )
          : ref.watch(recordListProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (records) => _buildReminderList(records),
            ),
    );
  }

  Widget _buildReminderList(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _showActiveOnly 
                  ? '暂无提醒' 
                  : '没有记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _ReminderCard(
          record: record,
          onToggleReminder: () => _toggleReminder(record),
          onEditRecord: () => _editRecord(record),
        );
      },
    );
  }

  Future<void> _toggleReminder(EpisodeRecord record) async {
    await ref.read(recordNotifierProvider.notifier).update(
      record.copyWith(hasReminder: !record.hasReminder),
    );
    ref.invalidate(recordListProvider);
    ref.invalidate(reminderRecordsProvider);
    ref.invalidate(reminderCountProvider);
  }

  void _editRecord(EpisodeRecord record) {
    // Navigate to edit screen
    Navigator.pop(context);
  }
}

class _ReminderCard extends StatelessWidget {
  final EpisodeRecord record;
  final VoidCallback onToggleReminder;
  final VoidCallback onEditRecord;

  const _ReminderCard({
    required this.record,
    required this.onToggleReminder,
    required this.onEditRecord,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEditRecord,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Reminder toggle
              Transform.scale(
                scale: 1.2,
                child: Switch(
                  value: record.hasReminder,
                  onChanged: (_) => onToggleReminder(),
                ),
              ),
              const SizedBox(width: 12),
              // Record info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.note.isNotEmpty 
                          ? record.note 
                          : l10n.noNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(record.occurredAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        if (record.isRecurring) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _getRepeatLabel(record.repeatType),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Media indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (record.hasPhotos)
                    const Icon(Icons.photo, size: 16, color: Colors.blue),
                  if (record.hasAudio)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.mic, size: 16, color: Colors.orange)),
                  if (record.hasVideos)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.videocam, size: 16, color: Colors.red)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getRepeatLabel(String repeatType) {
    switch (repeatType) {
      case 'daily': return '每天';
      case 'weekly': return '每周';
      case 'monthly': return '每月';
      case 'yearly': return '每年';
      default: return repeatType;
    }
  }
}

/// 批量设置提醒对话框
class BatchReminderDialog extends ConsumerStatefulWidget {
  final List<EpisodeRecord> records;
  final Function(bool enabled, String? repeatType) onConfirm;

  const BatchReminderDialog({
    super.key,
    required this.records,
    required this.onConfirm,
  });

  @override
  ConsumerState<BatchReminderDialog> createState() => _BatchReminderDialogState();
}

class _BatchReminderDialogState extends ConsumerState<BatchReminderDialog> {
  bool _enableReminder = true;
  String _repeatType = 'none';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.batchSetReminder),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('将为 ${widget.records.length} 条记录设置提醒'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('启用提醒'),
            value: _enableReminder,
            onChanged: (value) => setState(() => _enableReminder = value),
          ),
          if (_enableReminder) ...[
            const SizedBox(height: 8),
            Text(
              l10n.repeatType,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildRepeatChip('none', '不重复'),
                _buildRepeatChip('daily', '每天'),
                _buildRepeatChip('weekly', '每周'),
                _buildRepeatChip('monthly', '每月'),
                _buildRepeatChip('yearly', '每年'),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_enableReminder, _enableReminder ? _repeatType : null);
            Navigator.pop(context);
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildRepeatChip(String value, String label) {
    final isSelected = _repeatType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _repeatType = value),
    );
  }
}

/// 批量更新提醒对话框
Future<void> showBatchReminderDialog(
  BuildContext context,
  List<EpisodeRecord> records,
  Function(bool enabled, String? repeatType) onConfirm,
) async {
  await showDialog(
    context: context,
    builder: (_) => BatchReminderDialog(
      records: records,
      onConfirm: onConfirm,
    ),
  );
}