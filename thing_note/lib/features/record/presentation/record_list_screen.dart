import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thing_note/features/export/presentation/providers/export_import_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/presentation/widgets/record_card.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class RecordListScreen extends ConsumerStatefulWidget {
  const RecordListScreen({super.key});

  @override
  ConsumerState<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends ConsumerState<RecordListScreen> {
  final Set<int> _selectedRecordIds = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {
    ref.invalidate(recordListProvider);
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleSelect(int recordId) {
    setState(() {
      if (_selectedRecordIds.contains(recordId)) {
        _selectedRecordIds.remove(recordId);
      } else {
        _selectedRecordIds.add(recordId);
      }
      if (_selectedRecordIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _selectAll(List<EpisodeRecord> records) {
    setState(() {
      if (_selectedRecordIds.length == records.length) {
        _selectedRecordIds.clear();
        _isMultiSelectMode = false;
      } else {
        _selectedRecordIds.addAll(records.map((r) => r.id!).whereType<int>());
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteSelected(_selectedRecordIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(ctx)!.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedRecordIds) {
        await ref.read(recordNotifierProvider.notifier).delete(id);
      }
      setState(() {
        _isMultiSelectMode = false;
        _selectedRecordIds.clear();
      });
      ref.invalidate(recordListProvider);
    }
  }

  Future<void> _shareSelected() async {
    try {
      final recordsAsync = ref.read(recordListProvider);
      final records = recordsAsync.valueOrNull?.where((r) => _selectedRecordIds.contains(r.id)).toList() ?? [];
      if (records.isEmpty) return;

      final thingNamesAsync = ref.read(thingNameListProvider);
      final thingNames = thingNamesAsync.valueOrNull ?? [];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Consumer(
          builder: (context, ref, _) {
            final exportState = ref.watch(exportImportNotifierProvider);
            return AlertDialog(
              title: Text(AppLocalizations.of(ctx)!.exporting),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: exportState.progress),
                  const SizedBox(height: 16),
                  Text(exportState.statusMessage),
                ],
              ),
            );
          },
        ),
      );

      final zipFile = await ref.read(exportImportNotifierProvider.notifier).exportRecords(
        records: records,
        thingNames: thingNames,
      );

      if (mounted) Navigator.pop(context);

      if (zipFile != null && mounted) {
        await Share.shareXFiles([XFile(zipFile.path)], text: AppLocalizations.of(context)!.shareRecords(_selectedRecordIds.length));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareFailed(e.toString()))),
        );
      }
    }
  }

  void _showReminderList(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final reminderRecordsAsync = ref.watch(reminderRecordsProvider);
          final thingNamesAsync = ref.watch(thingNameListProvider);
          final thingNames = thingNamesAsync.valueOrNull ?? [];

          String? resolveThingName(int? thingNameId) {
            if (thingNameId == null) return null;
            try {
              return thingNames.firstWhere((tn) => tn.id == thingNameId).name;
            } catch (_) {
              return null;
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.alarm),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(dialogContext)!.reminderRecords),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: reminderRecordsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(AppLocalizations.of(dialogContext)!.loadFailed(err.toString())),
                ),
                data: (reminderRecords) {
                  if (reminderRecords.isEmpty) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(AppLocalizations.of(dialogContext)!.noReminderRecords),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: reminderRecords.length,
                    itemBuilder: (context, index) {
                      final record = reminderRecords[index];
                      final thingName = resolveThingName(record.thingNameId);
                      return ListTile(
                        leading: const Icon(Icons.alarm, color: Colors.orange),
                        title: Text(
                          thingName ?? (record.note.isNotEmpty ? record.note : AppLocalizations.of(context)!.noNote),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(record.occurredAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: AppLocalizations.of(context)!.closeReminder,
                          onPressed: () async {
                            await ref.read(recordNotifierProvider.notifier).update(
                                  record.copyWith(hasReminder: false),
                                );
                            ref.invalidate(recordListProvider);
                            ref.invalidate(recordDetailProvider(record.id!));
                            ref.invalidate(reminderRecordsProvider);
                            final updatedReminders = await ref.read(reminderRecordsProvider.future);
                            if (updatedReminders.isEmpty && context.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          context.push('/record/${record.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(dialogContext)!.cancel),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordListProvider);
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isMultiSelectMode) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedRecordIds.clear();
          });
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isMultiSelectMode
              ? Text(AppLocalizations.of(context)!.selectedCount(_selectedRecordIds.length))
              : Text(AppLocalizations.of(context)!.appTitle),
          leading: _isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedRecordIds.clear();
                    });
                  },
                )
              : null,
          actions: _isMultiSelectMode
              ? [
                  recordsAsync.when(
                    data: (records) => IconButton(
                      icon: Icon(
                        _selectedRecordIds.length == records.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      onPressed: () => _selectAll(records),
                      tooltip: AppLocalizations.of(context)!.selectAll,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _selectedRecordIds.isEmpty ? null : _shareSelected,
                    tooltip: AppLocalizations.of(context)!.share,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedRecordIds.isEmpty ? null : _deleteSelected,
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                ]
              : [
                  Consumer(
                    builder: (context, ref, _) {
                      final countAsync = ref.watch(reminderCountProvider);
                      return countAsync.when(
                        data: (count) {
                          if (count == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: IconButton(
                              onPressed: () => _showReminderList(context, ref),
                              icon: Badge(
                                label: Text('$count'),
                                child: const Icon(Icons.alarm),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.category),
                    onPressed: () => context.push('/settings/thing-names'),
                    tooltip: AppLocalizations.of(context)!.thingNameManage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: recordsAsync.when(
            loading: () => _buildShimmerLoading(),
            error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.loadFailed(err.toString()))),
            data: (records) {
              if (records.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noRecords,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.addFirstRecord,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              final thingNameMap = thingNamesAsync.valueOrNull;
              String? resolveThingName(int? thingNameId) {
                if (thingNameId == null || thingNameMap == null) return null;
                try {
                  return thingNameMap.firstWhere((tn) => tn.id == thingNameId).name;
                } catch (_) {
                  return null;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final isSelected = record.id != null && _selectedRecordIds.contains(record.id);
                  return _AnimatedListItem(
                    index: index,
                    child: InkWell(
                      onTap: _isMultiSelectMode
                          ? (record.id != null ? () => _toggleSelect(record.id!) : null)
                          : () => context.push('/record/${record.id}'),
                      onLongPress: record.id != null
                          ? () {
                              setState(() {
                                _isMultiSelectMode = true;
                                _selectedRecordIds.add(record.id!);
                              });
                            }
                          : null,
                      child: Container(
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                        child: Stack(
                          children: [
                            RecordCard(
                              record: record,
                              thingName: resolveThingName(record.thingNameId),
                              onTap: null,
                            ),
                            if (_isMultiSelectMode && record.id != null)
                              Positioned(
                                left: 8,
                                top: 8,
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: _isMultiSelectMode
            ? null
            : _AnimatedFab(
                onPressed: () {
                  context.push('/record/new');
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedFab({required this.onPressed, required this.child});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.92),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          child: widget.child,
        ),
      ),
    );
  }
}
