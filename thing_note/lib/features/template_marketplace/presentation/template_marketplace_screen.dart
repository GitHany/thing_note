import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/template_models.dart';
import 'package:thing_note/features/template_marketplace/data/template_marketplace_service.dart';

class TemplateMarketplaceScreen extends ConsumerStatefulWidget {
  const TemplateMarketplaceScreen({super.key});

  @override
  ConsumerState<TemplateMarketplaceScreen> createState() => _TemplateMarketplaceScreenState();
}

class _TemplateMarketplaceScreenState extends ConsumerState<TemplateMarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模板市场'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showPublishDialog(context),
            tooltip: '发布模板',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '浏览'),
            Tab(text: '我的'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模板...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // 分类筛选
          if (_tabController.index == 0)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: '全部',
                    isSelected: _selectedCategory == 'all',
                    onTap: () => setState(() => _selectedCategory = 'all'),
                  ),
                  ...TemplateCategory.values.map((category) => _CategoryChip(
                    label: category.label,
                    isSelected: _selectedCategory == category.value,
                    onTap: () => setState(() => _selectedCategory = category.value),
                  )),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BrowseTab(
                  category: _selectedCategory,
                  searchQuery: _searchController.text,
                ),
                const _MyTemplatesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPublishDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'work';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('发布模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '模板名称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: TemplateCategory.values.map((c) => DropdownMenuItem(
                    value: c.value,
                    child: Text(c.label),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final service = ref.read(templateMarketplaceServiceProvider);
                  await service.addTemplate(MarketplaceTemplate(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text,
                    category: selectedCategory,
                    description: descController.text,
                    templateData: '{}',
                    authorName: '我',
                    createdAt: DateTime.now(),
                  ));
                  ref.invalidate(marketplaceTemplatesProvider);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('模板发布成功')),
                  );
                }
              },
              child: const Text('发布'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 浏览标签页
class _BrowseTab extends ConsumerWidget {
  final String category;
  final String searchQuery;

  const _BrowseTab({
    required this.category,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = category == 'all'
        ? ref.watch(marketplaceTemplatesProvider)
        : ref.watch(templatesByCategoryProvider(category));

    return templatesAsync.when(
      data: (templates) {
        var filtered = templates;
        if (searchQuery.isNotEmpty) {
          filtered = templates.where((t) =>
            t.name.contains(searchQuery) ||
            (t.description?.contains(searchQuery) ?? false)
          ).toList();
        }

        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无模板'),
                SizedBox(height: 8),
                Text('成为第一个发布模板的人！', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final template = filtered[index];
            return _TemplateCard(
              template: template,
              onImport: () async {
                final service = ref.read(templateMarketplaceServiceProvider);
                await service.importTemplate(template);
                await service.incrementDownloadCount(template.id);
                ref.invalidate(marketplaceTemplatesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('模板已导入')),
                  );
                }
              },
              onRate: () => _showRateDialog(context, ref, template),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  void _showRateDialog(BuildContext context, WidgetRef ref, MarketplaceTemplate template) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('评价模板'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => selectedRating = index + 1),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: '评论 (可选)',
                  hintText: '写下你的使用体验...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final service = ref.read(templateMarketplaceServiceProvider);
                await service.addRating(TemplateRating(
                  id: DateTime.now().millisecondsSinceEpoch,
                  templateId: template.id,
                  rating: selectedRating,
                  comment: commentController.text.isNotEmpty ? commentController.text : null,
                  createdAt: DateTime.now(),
                ));
                ref.invalidate(marketplaceTemplatesProvider);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('感谢你的评价！')),
                );
              },
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 我的模板标签页
class _MyTemplatesTab extends ConsumerWidget {
  const _MyTemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(marketplaceTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        final myTemplates = templates.where((t) => t.authorName == '我').toList();

        if (myTemplates.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('还没有发布模板'),
                SizedBox(height: 8),
                Text(
                  '创建模板并分享给其他用户',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myTemplates.length,
          itemBuilder: (context, index) {
            final template = myTemplates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity( 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(template.name),
                subtitle: Text('下载 ${template.downloadCount} | 评分 ${template.rating.toStringAsFixed(1)}'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final service = ref.read(templateMarketplaceServiceProvider);
                      await service.deleteTemplate(template.id);
                      ref.invalidate(marketplaceTemplatesProvider);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 分类筛选芯片
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// 模板卡片
class _TemplateCard extends StatelessWidget {
  final MarketplaceTemplate template;
  final VoidCallback onImport;
  final VoidCallback onRate;

  const _TemplateCard({
    required this.template,
    required this.onImport,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final category = parseTemplateCategory(template.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(category.label, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ),
                if (template.isFeatured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('精选', style: TextStyle(fontSize: 12, color: Colors.amber)),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' ${template.rating.toStringAsFixed(1)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (template.description != null) ...[
              const SizedBox(height: 4),
              Text(
                template.description!,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.download, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${template.downloadCount}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                if (template.authorName != null) ...[
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(template.authorName!, style: TextStyle(color: Colors.grey[600])),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_border, size: 18),
                  label: const Text('评分'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('导入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}