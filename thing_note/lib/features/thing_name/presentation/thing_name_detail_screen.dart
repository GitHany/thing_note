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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    if (thingName.name == AppLocalizations.of(context)!.defaultThingName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.defaultNameProtected)),
      );
      return;
    }

    _nameController.text = thingName.name;
    _remarkController.text = thingName.remark ?? '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.editThingName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              maxLines: 3,
              decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.remark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
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
            child: Text(AppLocalizations.of(ctx)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteThingName(ThingName thingName) async {
    if (thingName.name == AppLocalizations.of(context)!.defaultThingName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.defaultThingNameCannotDelete)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteThingName),
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

    if (confirmed == true && mounted) {
      await ref.read(thingNameNotifierProvider.notifier).remove(thingName.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportRecords(List<EpisodeRecord> records, List<ThingName> thingNames) async {
    try {
      final zipFile = await ZipExporter.exportRecords(
        records: records,
        thingNames: thingNames,
      );
      if (mounted) {
        await Share.shareXFiles([XFile(zipFile.path)], text: AppLocalizations.of(context)!.shareRecords(records.length));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.exportFailed(e.toString()))),
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
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.loadFailed(err.toString()))),
      ),
      data: (thingName) {
        if (thingName == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(AppLocalizations.of(context)!.thingNameNotExist)),
          );
        }

        final records = recordsAsync.valueOrNull
                ?.where((r) => r.thingNameId == widget.thingNameId)
                .toList() ??
            [];
        final thingNames = allThingNamesAsync.valueOrNull ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(thingName.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: records.isEmpty ? null : () => _exportRecords(records, thingNames),
                tooltip: AppLocalizations.of(context)!.share,
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text(AppLocalizations.of(context)!.edit),
                    ),
                    onTap: () => _showEditDialog(thingName),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      title: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                  '${AppLocalizations.of(context)!.relatedRecords} (${records.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        AppLocalizations.of(context)!.noRelatedRecords,
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
