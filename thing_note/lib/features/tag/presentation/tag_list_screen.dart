import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/tag/presentation/providers/tag_provider.dart';

class TagListScreen extends ConsumerWidget {
  const TagListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = AppSpacing.getHorizontalPadding(screenWidth);
    final itemSpacing = AppSpacing.getItemSpacing(screenWidth);

    Future<void> refresh() async {
      ref.invalidate(tagListProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tags),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: tagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noTags,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.createFirstTag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(horizontalPadding),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
              return Card(
                margin: EdgeInsets.only(bottom: itemSpacing),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tagColor,
                    child: Text(
                      tag.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(tag.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push('/settings/tags/${tag.id}');
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocalizations.of(ctx)!.confirmDelete),
                            content: Text(AppLocalizations.of(ctx)!.confirmDeleteTag(tag.name)),
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
                          final repo = await ref.read(tagRepositoryProvider.future);
                          await repo.deleteTag(tag.id!);
                          ref.invalidate(tagListProvider);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
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
                  onTap: () => context.push('/settings/tags/${tag.id}'),
                ),
              );
            },
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/settings/tags/new'),
      child: const Icon(Icons.add),
    ),
  );
}
}