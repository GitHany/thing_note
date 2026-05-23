import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/knowledge_base/data/knowledge_base_provider.dart';
import 'package:thing_note/features/knowledge_base/domain/knowledge_entry.dart';

class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(knowledgeBaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索知识...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, '全部'),
                ...KnowledgeEntry.categories.map((c) => _buildCategoryChip(c, c)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (entries) {
                var filtered = entries;
                if (_selectedCategory != null) {
                  filtered = filtered.where((e) => e.category == _selectedCategory).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((e) =>
                    e.title.contains(_searchQuery) ||
                    e.content.contains(_searchQuery) ||
                    (e.tags?.contains(_searchQuery) ?? false)
                  ).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_books, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无知识条目', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('添加知识'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) => _buildEntryCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue.withOpacity(0.2),
      ),
    );
  }

  Widget _buildEntryCard(KnowledgeEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetailDialog(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(entry.category!, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    ),
                  const Spacer(),
                  if (entry.isFavorite == 1)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(entry.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                    Icon(Icons.label, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      entry.tags!,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${entry.useCount}次', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String? category;
    final tagsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('添加知识'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: '内容', border: OutlineInputBorder()),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
                  items: KnowledgeEntry.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: '标签（逗号分隔）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                  final now = DateTime.now().toIso8601String();
                  final entry = KnowledgeEntry(
                    title: titleCtrl.text,
                    content: contentCtrl.text,
                    category: category,
                    tags: tagsCtrl.text.isNotEmpty ? tagsCtrl.text : null,
                    createdAt: now,
                    updatedAt: now,
                  );
                  await ref.read(knowledgeBaseProvider.notifier).addEntry(entry);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(KnowledgeEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(entry.isFavorite == 1 ? Icons.star : Icons.star_border),
                    color: Colors.amber,
                    onPressed: () {
                      ref.read(knowledgeBaseProvider.notifier).toggleFavorite(entry.id!);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.category != null) ...[
                      Chip(label: Text(entry.category!)),
                      const SizedBox(height: 16),
                    ],
                    Text(entry.content, style: const TextStyle(fontSize: 16, height: 1.6)),
                    if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: entry.tagList.map((t) => Chip(label: Text('#$t'))).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('已查看 ${entry.useCount} 次', style: TextStyle(color: Colors.grey[600])),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(knowledgeBaseProvider.notifier).deleteEntry(entry.id!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}