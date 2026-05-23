import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_note_linking/data/note_link_provider.dart';
import 'package:thing_note/features/smart_note_linking/domain/note_link.dart';

class SmartNoteLinkingScreen extends ConsumerStatefulWidget {
  final int? recordId;

  const SmartNoteLinkingScreen({super.key, this.recordId});

  @override
  ConsumerState<SmartNoteLinkingScreen> createState() => _SmartNoteLinkingScreenState();
}

class _SmartNoteLinkingScreenState extends ConsumerState<SmartNoteLinkingScreen> {
  bool _showSuggestions = true;

  @override
  Widget build(BuildContext context) {
    final linksAsync = widget.recordId != null
        ? ref.watch(noteLinksProvider(widget.recordId!))
        : ref.watch(allLinksProvider);

    final suggestionsAsync = widget.recordId != null
        ? ref.watch(suggestedLinksProvider(widget.recordId!))
        : const AsyncValue.data(<NoteLink>[]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能笔记链接'),
        actions: [
          IconButton(
            icon: Icon(_showSuggestions ? Icons.lightbulb : Icons.lightbulb_outline),
            onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
            tooltip: '显示/隐藏建议',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSuggestions)
            _buildSuggestionsSection(suggestionsAsync),
          Expanded(
            child: linksAsync.when(
              data: (links) => _buildLinksList(links),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(AsyncValue<List<NoteLink>> suggestionsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity( 0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('智能建议', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              suggestionsAsync.when(
                data: (s) => Text('${s.length} 条建议', style: Theme.of(context).textTheme.bodySmall),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          suggestionsAsync.when(
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return const Text('暂无建议，尝试添加更多记录以获得关联推荐');
              }
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _buildSuggestionCard(suggestions[index]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载建议失败: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(NoteLink suggestion) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(suggestion.linkTypeIcon, size: 16, color: suggestion.linkTypeColor),
              const SizedBox(width: 4),
              Text(
                suggestion.linkType,
                style: TextStyle(fontSize: 12, color: suggestion.linkTypeColor),
              ),
              const Spacer(),
              _buildStrengthIndicator(suggestion.strengthScore),
            ],
          ),
          const Spacer(),
          Text(
            suggestion.linkBasis ?? '自动关联',
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => _addLink(suggestion),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('添加', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthIndicator(double score) {
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${(score * 100).toInt()}%',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLinksList(List<NoteLink> links) {
    if (links.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('暂无链接记录'),
            const SizedBox(height: 8),
            Text(
              '智能关联将自动发现相关记录',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: links.length,
      itemBuilder: (context, index) => _buildLinkCard(links[index]),
    );
  }

  Widget _buildLinkCard(NoteLink link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: link.linkTypeColor.withOpacity( 0.2),
          child: Icon(link.linkTypeIcon, color: link.linkTypeColor, size: 20),
        ),
        title: Text('记录 #${link.targetRecordId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: link.linkTypeColor.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(link.linkType, style: TextStyle(fontSize: 11, color: link.linkTypeColor)),
                ),
                const SizedBox(width: 8),
                _buildStrengthIndicator(link.strengthScore),
              ],
            ),
            if (link.linkBasis != null) ...[
              const SizedBox(height: 4),
              Text(link.linkBasis!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeLink(link.id!),
        ),
      ),
    );
  }

  Future<void> _addLink(NoteLink link) async {
    try {
      await ref.read(noteLinkNotifierProvider(widget.recordId).notifier).addLink(link);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  Future<void> _removeLink(int id) async {
    try {
      await ref.read(noteLinkNotifierProvider(widget.recordId).notifier).removeLink(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接已移除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }
}