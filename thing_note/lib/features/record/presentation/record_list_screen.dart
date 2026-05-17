import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thing_note/features/export/data/zip_exporter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/presentation/widgets/record_card.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

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
    Future.microtask(() => ref.read(recordListProvider));
  }

  Future<void> _refresh() async {
    ref.invalidate(recordListProvider);
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
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedRecordIds.length} 条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '删除',
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
      final thingNameMap = thingNamesAsync.valueOrNull;
      final thingNames = thingNameMap?.map((tn) => tn.name).toList() ?? [];

      final zipFile = await ZipExporter.exportRecords(
        records: records,
        thingNames: thingNames,
      );

      if (mounted) {
        await Share.shareXFiles([XFile(zipFile.path)], text: '分享 ${_selectedRecordIds.length} 条记录');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
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
              ? Text('已选择 ${_selectedRecordIds.length} 项')
              : const Text('事件记录'),
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
                      tooltip: '全选',
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _selectedRecordIds.isEmpty ? null : _shareSelected,
                    tooltip: '分享',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedRecordIds.isEmpty ? null : _deleteSelected,
                    tooltip: '删除',
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: recordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('加载失败: $err')),
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
                              '暂无记录',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击右下角按钮添加第一条记录',
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
                  return InkWell(
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
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: _isMultiSelectMode
            ? null
            : FloatingActionButton(
                onPressed: () {
                  context.push('/record/new');
                  ref.invalidate(recordListProvider);
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
