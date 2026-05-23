import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/batch_tag/data/batch_tag_provider.dart';

class BatchTagScreen extends ConsumerStatefulWidget {
  final List<int> selectedRecordIds;

  const BatchTagScreen({super.key, required this.selectedRecordIds});

  @override
  ConsumerState<BatchTagScreen> createState() => _BatchTagScreenState();
}

class _BatchTagScreenState extends ConsumerState<BatchTagScreen> {
  final _tagController = TextEditingController();
  final _suggestionController = TextEditingController();
  final _selectedTags = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batchTagNotifierProvider.notifier).loadTagsForRecords(widget.selectedRecordIds);
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchState = ref.watch(batchTagNotifierProvider);
    final statsAsync = ref.watch(tagStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Tag (${widget.selectedRecordIds.length} records)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTagDialog(context),
            tooltip: 'Add new tag',
          ),
        ],
      ),
      body: Column(
        children: [
          // Current tags section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Tags',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (batchState.currentTags.isEmpty)
                  const Text('No tags on selected records', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: batchState.currentTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Tag search and suggestions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _suggestionController,
                  decoration: InputDecoration(
                    hintText: 'Search tags...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _suggestionController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _suggestionController.clear();
                              ref.read(batchTagNotifierProvider.notifier).searchSuggestions('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    ref.read(batchTagNotifierProvider.notifier).searchSuggestions(value);
                  },
                ),
                if (batchState.suggestedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: batchState.suggestedTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          if (selected) {
                            ref.read(batchTagNotifierProvider.notifier).addTags([tag]);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Tag statistics
          Expanded(
            child: statsAsync.when(
              data: (stats) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Tag Statistics',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...stats.take(20).map((stat) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(stat.usageCount.toString()),
                        ),
                        title: Text(stat.tagName),
                        subtitle: stat.lastUsed != null
                            ? Text('Last used: ${_formatDate(stat.lastUsed!)}')
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            ref.read(batchTagNotifierProvider.notifier).addTags([stat.tagName]);
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tags updated for ${widget.selectedRecordIds.length} records')),
                      );
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    ref.read(batchTagNotifierProvider.notifier).removeTags([tag]);
  }

  void _showAddTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tag = _tagController.text.trim();
              if (tag.isNotEmpty) {
                ref.read(batchTagNotifierProvider.notifier).addTags([tag]);
                _tagController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}';
  }
}