import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thing_note/features/export/data/zip_exporter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/presentation/widgets/record_card.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

class ThingNameDetailScreen extends ConsumerStatefulWidget {
  final int thingNameId;

  const ThingNameDetailScreen({super.key, required this.thingNameId});

  @override
  ConsumerState<ThingNameDetailScreen> createState() => _ThingNameDetailScreenState();
}

class _ThingNameDetailScreenState extends ConsumerState<ThingNameDetailScreen> {
  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(ThingName thingName) async {
    if (thingName.name == '默认') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('默认事件名称不能被修改')),
      );
      return;
    }

    _nameController.text = thingName.name;
    _remarkController.text = thingName.remark ?? '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑事件名称'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              ref.read(thingNameNotifierProvider.notifier).update(
                thingName.id!,
                _nameController.text.trim(),
                remark: _remarkController.text.trim().isEmpty
                    ? null
                    : _remarkController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteThingName(ThingName thingName) async {
    if (thingName.name == '默认') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('默认事件名称不能被删除')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个事件名称吗？\n\n相关的记录不会被删除，但它们的事件名称会被移除。'),
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

    if (confirmed == true && mounted) {
      await ref.read(thingNameNotifierProvider.notifier).remove(thingName.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportRecords(List<EpisodeRecord> records, List<String> thingNames) async {
    try {
      final zipFile = await ZipExporter.exportRecords(
        records: records,
        thingNames: thingNames,
      );
      if (mounted) {
        await Share.shareXFiles([XFile(zipFile.path)], text: '分享 ${records.length} 条记录');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thingNameAsync = ref.watch(thingNameByIdProvider(widget.thingNameId));
    final recordsAsync = ref.watch(recordListProvider);
    final allThingNamesAsync = ref.watch(thingNameListProvider);

    return thingNameAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('加载失败: $err')),
      ),
      data: (thingName) {
        if (thingName == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('事件名称不存在')),
          );
        }

        final records = recordsAsync.valueOrNull
                ?.where((r) => r.thingNameId == widget.thingNameId)
                .toList() ??
            [];
        final thingNames = allThingNamesAsync.valueOrNull?.map((tn) => tn.name).toList() ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(thingName.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: records.isEmpty ? null : () => _exportRecords(records, thingNames),
                tooltip: '分享',
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('编辑'),
                    ),
                    onTap: () => _showEditDialog(thingName),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      title: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                    onTap: () => _deleteThingName(thingName),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thingName.remark != null && thingName.remark!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(thingName.remark!),
                  ),
                const SizedBox(height: 16),
                Text(
                  '相关记录 (${records.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        '暂无相关记录',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  )
                else
                  ...records.map((record) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RecordCard(
                          record: record,
                          thingName: thingName.name,
                          onTap: () => context.push('/record/${record.id}'),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}
