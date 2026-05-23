import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/features/tag/domain/tag.dart';
import 'package:thing_note/features/tag/presentation/providers/tag_provider.dart';

enum BatchEditType { thingName, addTags, removeTags, favorite, unfavorite, setReminder, removeReminder, batchMove }

class BatchEditDialog extends ConsumerStatefulWidget {
  final Set<int> selectedRecordIds;

  const BatchEditDialog({
    super.key,
    required this.selectedRecordIds,
  });

  @override
  ConsumerState<BatchEditDialog> createState() => _BatchEditDialogState();
}

class _BatchEditDialogState extends ConsumerState<BatchEditDialog> {
  BatchEditType? _selectedType;
  int? _selectedThingNameId;
  final Set<int> _selectedTagIds = {};
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final thingNamesAsync = ref.watch(thingNameListProvider);
    final tagsAsync = ref.watch(tagListProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit),
          const SizedBox(width: 8),
          Text(l10n.batchEdit),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectedCount(widget.selectedRecordIds.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_selectedType == null) ...[
              _buildEditOption(
                icon: Icons.category,
                title: l10n.changeThingName,
                subtitle: l10n.changeThingNameHint,
                onTap: () => setState(() => _selectedType = BatchEditType.thingName),
              ),
              _buildEditOption(
                icon: Icons.label,
                title: l10n.addTags,
                subtitle: l10n.addTagsHint,
                onTap: () => setState(() => _selectedType = BatchEditType.addTags),
              ),
              _buildEditOption(
                icon: Icons.label_off,
                title: l10n.removeTags,
                subtitle: l10n.removeTagsHint,
                onTap: () => setState(() => _selectedType = BatchEditType.removeTags),
              ),
              _buildEditOption(
                icon: Icons.star,
                title: l10n.markAsFavorite,
                subtitle: l10n.markAsFavoriteHint,
                onTap: () => _applyBatchEdit(BatchEditType.favorite),
              ),
              _buildEditOption(
                icon: Icons.star_border,
                title: l10n.removeFavorite,
                subtitle: l10n.removeFavoriteHint,
                onTap: () => _applyBatchEdit(BatchEditType.unfavorite),
              ),
              _buildEditOption(
                icon: Icons.alarm_on,
                title: l10n.batchSetReminder,
                subtitle: l10n.batchSetReminderHint,
                onTap: () => setState(() => _selectedType = BatchEditType.setReminder),
              ),
              _buildEditOption(
                icon: Icons.alarm_off,
                title: l10n.batchRemoveReminder,
                subtitle: l10n.batchRemoveReminderHint,
                onTap: () => _applyBatchEdit(BatchEditType.removeReminder),
              ),
            ] else ...[
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedType = null),
                  ),
                  Text(
                    _getTypeTitle(l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTypeContent(thingNamesAsync, tagsAsync, l10n),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        if (_selectedType != null)
          FilledButton(
            onPressed: _isProcessing ? null : _confirmEdit,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirm),
          ),
      ],
    );
  }

  Widget _buildEditOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: _isProcessing ? null : onTap,
    );
  }

  String _getTypeTitle(AppLocalizations l10n) {
    switch (_selectedType) {
      case BatchEditType.thingName:
        return l10n.selectThingName;
      case BatchEditType.addTags:
      case BatchEditType.removeTags:
        return l10n.selectTags;
      case BatchEditType.setReminder:
        return l10n.setReminder;
      default:
        return '';
    }
  }

  Widget _buildTypeContent(
    AsyncValue<List<ThingName>> thingNamesAsync,
    AsyncValue<List<Tag>> tagsAsync,
    AppLocalizations l10n,
  ) {
    switch (_selectedType) {
      case BatchEditType.thingName:
        return _buildThingNameSelector(thingNamesAsync, l10n);
      case BatchEditType.addTags:
        return _buildTagSelector(tagsAsync, l10n, isAdding: true);
      case BatchEditType.removeTags:
        return _buildTagSelector(tagsAsync, l10n, isAdding: false);
      case BatchEditType.setReminder:
        return _buildReminderSelector(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildThingNameSelector(
    AsyncValue<List<ThingName>> thingNamesAsync,
    AppLocalizations l10n,
  ) {
    return thingNamesAsync.when(
      data: (thingNames) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.doNotSelect),
              selected: _selectedThingNameId == null,
              trailing: _selectedThingNameId == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => setState(() => _selectedThingNameId = null),
            ),
            const Divider(),
            ...thingNames.map((tn) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(tn.name),
                  selected: _selectedThingNameId == tn.id,
                  trailing: _selectedThingNameId == tn.id
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => setState(() => _selectedThingNameId = tn.id),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
    );
  }

  Widget _buildTagSelector(
    AsyncValue<List<Tag>> tagsAsync,
    AppLocalizations l10n, {
    required bool isAdding,
  }) {
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text(l10n.noTags)),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedTagIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(l10n.selectedCount(_selectedTagIds.length)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedTagIds.clear()),
                      child: Text(l10n.clearSelection),
                    ),
                  ],
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: tags.map((tag) {
                    final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                    final isSelected = _selectedTagIds.contains(tag.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedTagIds.add(tag.id!);
                          } else {
                            _selectedTagIds.remove(tag.id!);
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
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
    );
  }

  Future<void> _confirmEdit() async {
    if (_selectedType == null) return;

    setState(() => _isProcessing = true);

    try {
      switch (_selectedType!) {
        case BatchEditType.thingName:
          await _batchUpdateThingName();
          break;
        case BatchEditType.addTags:
          await _batchAddTags();
          break;
        case BatchEditType.removeTags:
          await _batchRemoveTags();
          break;
        case BatchEditType.setReminder:
          await _batchSetReminder();
          break;
        default:
          break;
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.batchEditFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _applyBatchEdit(BatchEditType type) async {
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(recordNotifierProvider.notifier);

      for (final id in widget.selectedRecordIds) {
        final record = await ref.read(recordDetailProvider(id).future);
        if (record == null) continue;

        switch (type) {
          case BatchEditType.favorite:
            await notifier.update(record.copyWith(isFavorite: true));
            break;
          case BatchEditType.unfavorite:
            await notifier.update(record.copyWith(isFavorite: false));
            break;
          case BatchEditType.removeReminder:
            await notifier.update(record.copyWith(hasReminder: false, repeatType: 'none'));
            break;
          default:
            break;
        }
      }

      ref.invalidate(recordListProvider);
      ref.invalidate(favoriteCountProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.batchEditFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _batchUpdateThingName() async {
    final notifier = ref.read(recordNotifierProvider.notifier);

    for (final id in widget.selectedRecordIds) {
      final record = await ref.read(recordDetailProvider(id).future);
      if (record == null) continue;
      await notifier.update(record.copyWith(thingNameId: _selectedThingNameId));
    }

    ref.invalidate(recordListProvider);
  }

  Future<void> _batchAddTags() async {
    if (_selectedTagIds.isEmpty) return;

    final tagRepo = await ref.read(tagRepositoryProvider.future);

    for (final id in widget.selectedRecordIds) {
      // Get current tags for this record
      final currentTags = await tagRepo.getTagsForRecord(id);
      final currentTagIds = currentTags.map((t) => t.id!).toSet();

      // Add new tags (avoid duplicates)
      final newTagIds = {...currentTagIds, ..._selectedTagIds}.toList();
      await tagRepo.setTagsForRecord(id, newTagIds);
    }

    ref.invalidate(recordListProvider);
  }

  Future<void> _batchRemoveTags() async {
    if (_selectedTagIds.isEmpty) return;

    final tagRepo = await ref.read(tagRepositoryProvider.future);

    for (final id in widget.selectedRecordIds) {
      // Get current tags for this record
      final currentTags = await tagRepo.getTagsForRecord(id);
      final currentTagIds = currentTags.map((t) => t.id!).toSet();

      // Remove selected tags
      final newTagIds = currentTagIds.where((id) => !_selectedTagIds.contains(id)).toList();
      await tagRepo.setTagsForRecord(id, newTagIds);
    }

    ref.invalidate(recordListProvider);
  }

  // State for reminder selection
  String _selectedRepeatType = 'none';

  Widget _buildReminderSelector(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.setReminder),
          value: true,
          onChanged: null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.repeatType,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildRepeatChip(l10n.repeatNone, 'none'),
                  _buildRepeatChip(l10n.repeatDaily, 'daily'),
                  _buildRepeatChip(l10n.repeatWeekly, 'weekly'),
                  _buildRepeatChip(l10n.repeatMonthly, 'monthly'),
                  _buildRepeatChip(l10n.repeatYearly, 'yearly'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRepeatChip(String label, String value) {
    final isSelected = _selectedRepeatType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedRepeatType = value),
    );
  }

  Future<void> _batchSetReminder() async {
    final notifier = ref.read(recordNotifierProvider.notifier);

    for (final id in widget.selectedRecordIds) {
      final record = await ref.read(recordDetailProvider(id).future);
      if (record == null) continue;
      await notifier.update(record.copyWith(
        hasReminder: true,
        repeatType: _selectedRepeatType,
      ));
    }

    ref.invalidate(recordListProvider);
    ref.invalidate(reminderCountProvider);
    ref.invalidate(reminderRecordsProvider);
  }
}