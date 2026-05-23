import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class LinkRecordsDialog extends ConsumerStatefulWidget {
  final int currentRecordId;
  final VoidCallback onLinked;

  const LinkRecordsDialog({
    super.key,
    required this.currentRecordId,
    required this.onLinked,
  });

  @override
  ConsumerState<LinkRecordsDialog> createState() => _LinkRecordsDialogState();
}

class _LinkRecordsDialogState extends ConsumerState<LinkRecordsDialog> {
  int? _selectedRecordId;
  bool _isLinking = false;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordListProvider);
    final linkedRecordsAsync = ref.watch(linkedRecordsProvider(widget.currentRecordId));
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.link),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.linkRecords),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Already linked records
            Text(
              AppLocalizations.of(context)!.currentLinks,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            linkedRecordsAsync.when(
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(AppLocalizations.of(context)!.loadFailed('')),
              data: (linkedRecords) {
                if (linkedRecords.isEmpty) {
                  return Container(
                    height: 50,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.noLinkedRecords,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  );
                }
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: linkedRecords.length,
                    itemBuilder: (context, index) {
                      final linked = linkedRecords[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Icon(
                          _getRecordIcon(linked),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          linked.note.isNotEmpty ? linked.note : AppLocalizations.of(context)!.noNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormatter.formatDate(linked.occurredAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off, size: 20),
                          onPressed: () async {
                            await _unlinkRecord(linked.id!);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/record/${linked.id}');
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.selectRecordToLink,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: recordsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text(AppLocalizations.of(context)!.loadFailed(err.toString()))),
                data: (records) {
                  // Filter out current record and already linked
                  final linkedAsync = ref.read(linkedRecordsProvider(widget.currentRecordId));
                  final linkedIds = linkedAsync.valueOrNull?.map((r) => r.id!).toSet() ?? {};
                  
                  final availableRecords = records
                      .where((r) => r.id != widget.currentRecordId && !linkedIds.contains(r.id))
                      .toList();

                  if (availableRecords.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.noRecordsToLink,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableRecords.length,
                    itemBuilder: (context, index) {
                      final record = availableRecords[index];
                      final isSelected = _selectedRecordId == record.id;
                      final thingNames = thingNamesAsync.valueOrNull ?? [];
                      String? thingName;
                      try {
                        final found = thingNames.firstWhere((tn) => tn.id == record.thingNameId);
                        thingName = found.name;
                      } catch (_) {}

                      return Card(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getRecordIcon(record),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            thingName ?? (record.note.isNotEmpty ? record.note : AppLocalizations.of(context)!.noNote),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormatter.formatDateTime(record.occurredAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedRecordId = isSelected ? null : record.id;
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _selectedRecordId == null || _isLinking
              ? null
              : () async {
                  setState(() => _isLinking = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final l10n = AppLocalizations.of(context)!;
                  try {
                    await ref.read(recordNotifierProvider.notifier).createLink(
                          widget.currentRecordId,
                          _selectedRecordId!,
                        );
                    widget.onLinked();
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.linkCreated)),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLinking = false);
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.linkFailed(e.toString()))),
                      );
                    }
                  }
                },
          child: _isLinking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.link),
        ),
      ],
    );
  }

  IconData _getRecordIcon(EpisodeRecord record) {
    if (record.hasVideos) return Icons.videocam;
    if (record.hasPhotos) return Icons.photo;
    if (record.hasAudio) return Icons.mic;
    if (record.note.isNotEmpty) return Icons.note;
    return Icons.event;
  }

  Future<void> _unlinkRecord(int linkedRecordId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(recordRepositoryProvider);
      await repo.deleteLinkByRecords(widget.currentRecordId, linkedRecordId);
      ref.invalidate(linkedRecordsProvider(widget.currentRecordId));
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.linkRemoved)),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.linkFailed(e.toString()))),
        );
      }
    }
  }
}