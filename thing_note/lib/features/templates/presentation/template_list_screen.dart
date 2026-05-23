import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/templates/domain/record_template.dart';
import 'package:thing_note/features/templates/presentation/providers/template_provider.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recordTemplates),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (templates) {
          if (templates.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(context, ref, template);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTemplates,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.createFirstTemplate,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WidgetRef ref, RecordTemplate template) {
    final thingNamesAsync = ref.watch(thingNameListProvider);
    ThingName? thingName;

    if (thingNamesAsync.hasValue) {
      try {
        thingName = thingNamesAsync.value!.firstWhere(
          (tn) => tn.id == template.defaultThingNameId,
        );
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(template.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thingName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(thingName.name),
                ],
              ),
            ],
            if (template.defaultDurationSec > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text('${template.defaultDurationSec ~/ 60} min'),
                ],
              ),
            ],
            if (template.defaultNote.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                template.defaultNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog(context, ref, template);
            } else if (value == 'edit') {
              _showTemplateDialog(context, ref, template: template);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.delete,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref, {RecordTemplate? template}) {
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final noteController = TextEditingController(text: template?.defaultNote ?? '');
    int? selectedThingNameId = template?.defaultThingNameId;
    final int defaultDurationSec = template?.defaultDurationSec ?? 0;
    bool hasReminder = template?.hasReminder ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final thingNamesAsync = ref.watch(thingNameListProvider);

            return AlertDialog(
              title: Text(isEditing
                  ? AppLocalizations.of(dialogContext)!.editTag
                  : AppLocalizations.of(dialogContext)!.createTemplate),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(dialogContext)!.templateName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    thingNamesAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error loading'),
                      data: (thingNames) {
                        return DropdownButtonFormField<int?>(
                          value: selectedThingNameId,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(dialogContext)!.thingName,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(AppLocalizations.of(dialogContext)!.doNotSelect),
                            ),
                            ...thingNames.map((tn) => DropdownMenuItem<int?>(
                                  value: tn.id,
                                  child: Text(tn.name),
                                )),
                          ],
                          onChanged: (value) {
                            setModalState(() => selectedThingNameId = value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(dialogContext)!.note,
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(dialogContext)!.reminder),
                      value: hasReminder,
                      onChanged: (value) {
                        setModalState(() => hasReminder = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final newTemplate = RecordTemplate(
                      id: template?.id,
                      name: nameController.text.trim(),
                      defaultThingNameId: selectedThingNameId,
                      defaultDurationSec: defaultDurationSec,
                      defaultNote: noteController.text.trim(),
                      hasReminder: hasReminder,
                      createdAt: template?.createdAt ?? DateTime.now(),
                    );

                    if (isEditing) {
                      await ref.read(templateNotifierProvider.notifier).updateTemplate(newTemplate);
                    } else {
                      await ref.read(templateNotifierProvider.notifier).create(newTemplate);
                    }

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(AppLocalizations.of(dialogContext)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, RecordTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteTag(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(templateNotifierProvider.notifier).delete(template.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              AppLocalizations.of(ctx)!.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}