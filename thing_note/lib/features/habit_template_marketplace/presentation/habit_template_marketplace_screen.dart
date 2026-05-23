import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_template_marketplace/data/habit_template_repository.dart';
import 'package:thing_note/features/habit_template_marketplace/domain/habit_template.dart';

final templatesProvider = FutureProvider<List<HabitTemplate>>((ref) async {
  final repository = ref.watch(habitTemplateRepositoryProvider);
  await repository.initializeDefaultTemplates();
  return repository.getAllTemplates();
});

final templateByCategoryProvider = FutureProvider.family<List<HabitTemplate>, String>((ref, category) async {
  final repository = ref.watch(habitTemplateRepositoryProvider);
  return repository.getTemplatesByCategory(category);
});

final categoryStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(habitTemplateRepositoryProvider);
  return repository.getCategoryStats();
});

class HabitTemplateMarketplaceScreen extends ConsumerStatefulWidget {
  const HabitTemplateMarketplaceScreen({super.key});

  @override
  ConsumerState<HabitTemplateMarketplaceScreen> createState() => _HabitTemplateMarketplaceScreenState();
}

class _HabitTemplateMarketplaceScreenState extends ConsumerState<HabitTemplateMarketplaceScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final categories = ['健康', '学习', '工作', '生活', '运动', '冥想', '阅读', '其他'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯模板市场'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模板...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(context, '全部', null),
                ...categories.map((c) => _buildCategoryChip(context, c, c)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                var filtered = templates;
                if (_selectedCategory != null) {
                  filtered = filtered.where((t) => t.category == _selectedCategory).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((t) =>
                      t.templateName.contains(_searchQuery) ||
                      (t.description?.contains(_searchQuery) ?? false)).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 16),
                        const Text('没有找到匹配的模板'),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildTemplateCard(filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTemplateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }

  Widget _buildTemplateCard(HabitTemplate template) {
    return Card(
      child: InkWell(
        onTap: () => _showTemplateDetail(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        template.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.templateName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (template.description != null)
                Expanded(
                  child: Text(
                    template.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.download, size: 14, color: Theme.of(context).disabledColor),
                  const SizedBox(width: 4),
                  Text(
                    '${template.useCount} 次使用',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDetail(HabitTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.templateName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(template.category)),
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(' ${template.rating.toStringAsFixed(1)}'),
              ],
            ),
            if (template.description != null) ...[
              const SizedBox(height: 16),
              Text(template.description!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('关闭'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _importTemplate(template),
                    icon: const Icon(Icons.download),
                    label: const Text('导入'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importTemplate(HabitTemplate template) async {
    final repository = ref.read(habitTemplateRepositoryProvider);
    await repository.incrementUseCount(template.id!);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入模板: ${template.templateName}')),
      );
    }
  }

  Future<void> _showCreateTemplateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = '生活';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建模板'),
          content: Column(
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
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: '分类'),
                items: ['健康', '学习', '工作', '生活', '运动', '冥想', '阅读', '其他']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
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
                if (nameController.text.isNotEmpty) {
                  final repository = ref.read(habitTemplateRepositoryProvider);
                  await repository.insertTemplate(HabitTemplate(
                    templateName: nameController.text,
                    category: selectedCategory,
                    description: descController.text.isNotEmpty ? descController.text : null,
                  ));
                  ref.invalidate(templatesProvider);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}