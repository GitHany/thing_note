import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_link_enhance/data/record_link_provider.dart';
import 'package:thing_note/features/record_link_enhance/domain/record_link.dart';

class RecordLinkEnhanceScreen extends ConsumerWidget {
  final int recordId;

  const RecordLinkEnhanceScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(recordLinkNotifierProvider);
    final suggestionsAsync = ref.watch(linkSuggestionsProvider(recordId));
    final statsAsync = ref.watch(linkStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(recordLinkNotifierProvider.notifier).loadLinks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            data: (stats) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total', stats.totalLinks.toString()),
                    _buildStatItem('Reference', stats.referenceLinks.toString()),
                    _buildStatItem('Related', stats.relatedLinks.toString()),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Suggestions
          suggestionsAsync.when(
            data: (suggestions) {
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested Links',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              child: InkWell(
                                onTap: () {
                                  ref.read(recordLinkNotifierProvider.notifier).createLink(
                                    suggestion.targetRecordId,
                                    linkType: 'related',
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggestion.targetNote.isNotEmpty
                                            ? (suggestion.targetNote.length > 30
                                                ? '${suggestion.targetNote.substring(0, 30)}...'
                                                : suggestion.targetNote)
                                            : 'Record #${suggestion.targetRecordId}',
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(Icons.link, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            suggestion.similarityScore.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Existing links
          Expanded(
            child: linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No links yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Suggestions appear above', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return _buildLinkCard(context, ref, link);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLinkRecordDialog(context, ref),
        child: const Icon(Icons.add_link),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLinkCard(BuildContext context, WidgetRef ref, EnhancedRecordLink link) {
    final isOutgoing = link.sourceRecordId == recordId;
    final linkedRecordId = isOutgoing ? link.targetRecordId : link.sourceRecordId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLinkTypeColor(link.linkType),
          child: Icon(
            _getLinkTypeIcon(link.linkType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          isOutgoing ? 'Links to #$linkedRecordId' : 'Linked from #$linkedRecordId',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${link.linkType}'),
            if (link.note != null) Text(link.note!, style: const TextStyle(fontSize: 12)),
            Text(_formatDate(link.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            ref.read(recordLinkNotifierProvider.notifier).deleteLink(link.id!);
          },
        ),
      ),
    );
  }

  Color _getLinkTypeColor(String linkType) {
    switch (linkType) {
      case 'reference':
        return Colors.blue;
      case 'parent':
        return Colors.purple;
      case 'child':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getLinkTypeIcon(String linkType) {
    switch (linkType) {
      case 'reference':
        return Icons.link;
      case 'parent':
        return Icons.arrow_upward;
      case 'child':
        return Icons.arrow_downward;
      default:
        return Icons.connect_without_contact;
    }
  }

  void _showLinkRecordDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Record'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Record ID',
            hintText: 'Enter record ID to link',
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
              final targetId = int.tryParse(controller.text);
              if (targetId != null) {
                ref.read(recordLinkNotifierProvider.notifier).createLink(targetId);
                Navigator.pop(context);
              }
            },
            child: const Text('Link'),
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
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}