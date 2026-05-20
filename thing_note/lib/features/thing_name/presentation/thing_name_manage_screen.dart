import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/app/theme/app_theme.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ThingNameManageScreen extends ConsumerStatefulWidget {
  const ThingNameManageScreen({super.key});

  @override
  ConsumerState<ThingNameManageScreen> createState() => _ThingNameManageScreenState();
}

class _ThingNameManageScreenState extends ConsumerState<ThingNameManageScreen> {
  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _isMultiSelectMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    _nameController.clear();
    _remarkController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.addThingName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.name,
                hintText: AppLocalizations.of(ctx)!.pleaseEnterThingName,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.remark,
                hintText: AppLocalizations.of(ctx)!.pleaseEnterRemark,
              ),
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
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              if (name == AppLocalizations.of(context)!.defaultThingName) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.cannotCreateDefaultName)),
                );
                return;
              }
              final existingNames = ref.read(thingNameListProvider).valueOrNull ?? [];
              final isDuplicate = existingNames.any(
                (tn) => tn.name.toLowerCase() == name.toLowerCase(),
              );
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.thingNameAlreadyExists(name))),
                );
                return;
              }
              ref.read(thingNameNotifierProvider.notifier).add(
                name,
                remark: _remarkController.text.trim().isEmpty
                    ? null
                    : _remarkController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(ctx)!.add),
          ),
        ],
      ),
    );
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _selectAll(List<int> ids) {
    setState(() {
      if (_selectedIds.length == ids.length) {
        _selectedIds.clear();
        _isMultiSelectMode = false;
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final defaultId = ref.read(thingNameListProvider).valueOrNull
        ?.firstWhere((tn) => tn.name == AppLocalizations.of(context)!.defaultThingName, orElse: () => ThingName(name: '', createdAt: DateTime.now()))
        .id;
    final idsToDelete = _selectedIds.where((id) => id != defaultId).toList();
    
    if (idsToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.defaultThingNameCannotDelete)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteSelectedThingNames(idsToDelete.length)),
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
      for (final id in idsToDelete) {
        await ref.read(thingNameNotifierProvider.notifier).remove(id);
      }
      setState(() {
        _isMultiSelectMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text(AppLocalizations.of(context)!.selectedCount(_selectedIds.length))
            : Text(AppLocalizations.of(context)!.thingNameManage),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: _isMultiSelectMode
            ? thingNamesAsync.when(
                data: (thingNames) => [
                  IconButton(
                    icon: Icon(
                      _selectedIds.length == thingNames.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    onPressed: () => _selectAll(thingNames.map((t) => t.id!).toList()),
                    tooltip: AppLocalizations.of(context)!.selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                ],
                loading: () => [],
                error: (_, __) => [],
              )
            : [],
      ),
      body: thingNamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(AppLocalizations.of(context)!.loadFailed(err.toString()))),
        data: (thingNames) {
          if (thingNames.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_special_outlined,
                      size: 96,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noThingNames,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.tapToAddThingName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: thingNames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final thingName = thingNames[index];
              final isSelected = thingName.id != null && _selectedIds.contains(thingName.id);
              
              return Container(
                decoration: isSelected
                    ? AppTheme.softCardDecoration(
                        context,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      )
                    : AppTheme.softCardDecoration(context),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isMultiSelectMode && thingName.id != null
                      ? () => _toggleSelect(thingName.id!)
                      : () => context.push('/settings/thing-names/${thingName.id}'),
                  onLongPress: thingName.id != null
                      ? () {
                          setState(() {
                            _isMultiSelectMode = true;
                            _selectedIds.add(thingName.id!);
                          });
                        }
                      : null,
                  child: ListTile(
                    title: Text(thingName.name),
                    subtitle: thingName.remark != null && thingName.remark!.isNotEmpty
                        ? Text(thingName.remark!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: _isMultiSelectMode && thingName.id != null
                        ? Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            ),
    );
  }
}
