import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/batch/domain/batch_operation_service.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/features/tag/presentation/providers/tag_provider.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class BatchOperationScreen extends ConsumerStatefulWidget {
  final List<int> selectedRecordIds;

  const BatchOperationScreen({
    super.key,
    required this.selectedRecordIds,
  });

  @override
  ConsumerState<BatchOperationScreen> createState() => _BatchOperationScreenState();
}

class _BatchOperationScreenState extends ConsumerState<BatchOperationScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.batchOperations),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.processing),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 选择摘要
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.selectedRecordIds.length}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.selectedRecords(widget.selectedRecordIds.length),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                l10n.batchOperationDesc,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 操作列表
                Text(
                  l10n.availableOperations,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                _OperationTile(
                  icon: Icons.access_time,
                  title: l10n.adjustTime,
                  subtitle: l10n.adjustTimeDesc,
                  onTap: () => _showTimeAdjustmentDialog(context),
                ),
                _OperationTile(
                  icon: Icons.category,
                  title: l10n.changeThingName,
                  subtitle: l10n.changeThingNameDesc,
                  onTap: () => _showThingNamePicker(context),
                ),
                _OperationTile(
                  icon: Icons.star,
                  title: l10n.toggleFavorite,
                  subtitle: l10n.toggleFavoriteDesc,
                  onTap: () => _toggleFavorite(true),
                ),
                _OperationTile(
                  icon: Icons.star_border,
                  title: l10n.removeFavorite,
                  subtitle: l10n.removeFavoriteDesc,
                  onTap: () => _toggleFavorite(false),
                ),
                _OperationTile(
                  icon: Icons.label,
                  title: l10n.addTags,
                  subtitle: l10n.addTagsDesc,
                  onTap: () => _showTagPicker(context),
                ),
              ],
            ),
    );
  }

  Future<void> _showTimeAdjustmentDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    int offsetMinutes = 0;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.adjustTime),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adjustTimeTip),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() => offsetMinutes -= 5),
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${offsetMinutes >= 0 ? '+' : ''}$offsetMinutes min',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => offsetMinutes += 5),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text(l10n.minus15),
                    onPressed: () => setState(() => offsetMinutes = -15),
                  ),
                  ActionChip(
                    label: Text(l10n.plus15),
                    onPressed: () => setState(() => offsetMinutes = 15),
                  ),
                  ActionChip(
                    label: Text(l10n.minus60),
                    onPressed: () => setState(() => offsetMinutes = -60),
                  ),
                  ActionChip(
                    label: Text(l10n.plus60),
                    onPressed: () => setState(() => offsetMinutes = 60),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, offsetMinutes),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _executeBatchOperation(BatchOperation(
        type: BatchOperationType.changeTime,
        recordIds: widget.selectedRecordIds,
        parameters: {'offset_minutes': result},
      ));
    }
  }

  Future<void> _showThingNamePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final thingNamesAsync = ref.read(thingNameListProvider);
    final thingNames = thingNamesAsync.valueOrNull ?? [];

    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectThingName),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: thingNames.length,
            itemBuilder: (context, index) {
              final thingName = thingNames[index];
              return ListTile(
                title: Text(thingName.name),
                onTap: () => Navigator.pop(ctx, thingName.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (result != null) {
      await _executeBatchOperation(BatchOperation(
        type: BatchOperationType.changeThingName,
        recordIds: widget.selectedRecordIds,
        parameters: {'thing_name_id': result},
      ));
    }
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    await _executeBatchOperation(BatchOperation(
      type: BatchOperationType.changeFavorite,
      recordIds: widget.selectedRecordIds,
      parameters: {'is_favorite': isFavorite},
    ));
  }

  Future<void> _showTagPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final tagsAsync = ref.read(tagListProvider);
    final tags = tagsAsync.valueOrNull ?? [];

    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noTags)),
      );
      return;
    }

    final selectedTagIds = await showDialog<List<int>>(
      context: context,
      builder: (ctx) {
        final selectedTags = <int>[];
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(l10n.addTags),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                    return CheckboxListTile(
                      value: selectedTags.contains(tag.id),
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            selectedTags.add(tag.id!);
                          } else {
                            selectedTags.remove(tag.id);
                          }
                        });
                      },
                      title: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: tagColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(tag.name),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: selectedTags.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, selectedTags),
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedTagIds != null && selectedTagIds.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        final tagRepo = await ref.read(tagRepositoryProvider.future);
        for (final recordId in widget.selectedRecordIds) {
          final existingTags = await tagRepo.getTagsForRecord(recordId);
          final existingTagIds = existingTags.map((t) => t.id!).toSet();
          final newTagIds = {...existingTagIds, ...selectedTagIds}.toList();
          await tagRepo.setTagsForRecord(recordId, newTagIds);
        }
        ref.invalidate(recordListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.batchOperationSuccess(widget.selectedRecordIds.length)),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.batchOperationFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _executeBatchOperation(BatchOperation operation) async {
    setState(() => _isProcessing = true);

    try {
      final recordsAsync = ref.read(recordListProvider);
      final records = recordsAsync.valueOrNull ?? [];

      final recordsToUpdate = records.where((r) =>
          r.id != null && widget.selectedRecordIds.contains(r.id)).toList();

      final service = BatchOperationService();
      final updatedRecords = await service.applyOperation(recordsToUpdate, operation);

      // 更新记录
      for (final record in updatedRecords) {
        if (record.id != null) {
          await ref.read(recordNotifierProvider.notifier).update(record);
        }
      }

      ref.invalidate(recordListProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.batchOperationSuccess(updatedRecords.length)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.batchOperationFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _OperationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OperationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}