import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_template/data/smart_template_repository.dart';
import 'package:thing_note/features/smart_template/domain/smart_template.dart';
import 'package:go_router/go_router.dart';

class SmartTemplateScreen extends ConsumerStatefulWidget {
  const SmartTemplateScreen({super.key});

  @override
  ConsumerState<SmartTemplateScreen> createState() => _SmartTemplateScreenState();
}

class _SmartTemplateScreenState extends ConsumerState<SmartTemplateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SmartTemplate> _allTemplates = [];
  List<SmartTemplate> _favoriteTemplates = [];
  List<TemplateSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = ['全部', '工作', '学习', '健康', '生活'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final repo = ref.read(smartTemplateRepositoryProvider);
    await repo.initDefaultTemplates();
    
    final results = await Future.wait([
      repo.getAllTemplates(),
      repo.getFavoriteTemplates(),
      repo.getSuggestions(),
    ]);
    
    setState(() {
      _allTemplates = results[0] as List<SmartTemplate>;
      _favoriteTemplates = results[1] as List<SmartTemplate>;
      _suggestions = results[2] as List<TemplateSuggestion>;
      _isLoading = false;
    });
  }

  List<SmartTemplate> get _filteredTemplates {
    if (_selectedCategory == null || _selectedCategory == '全部') {
      return _allTemplates;
    }
    return _allTemplates.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _showAISuggestions,
            tooltip: 'AI 推荐',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '模板', icon: Icon(Icons.grid_view)),
            Tab(text: '收藏', icon: Icon(Icons.star)),
            Tab(text: '推荐', icon: Icon(Icons.lightbulb)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesTab(),
                _buildFavoritesTab(),
                _buildSuggestionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTemplateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: _filteredTemplates.isEmpty
              ? _buildEmptyState('暂无模板', '点击右下角按钮创建模板')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (context, index) {
                    final template = _filteredTemplates[index];
                    return _TemplateCard(
                      template: template,
                      onTap: () => _useTemplate(template),
                      onLongPress: () => _showTemplateOptions(template),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category ||
              (category == '全部' && _selectedCategory == null);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected && category != '全部' ? category : null;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteTemplates.isEmpty) {
      return _buildEmptyState('暂无收藏', '长按模板卡片进行收藏');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _favoriteTemplates.length,
      itemBuilder: (context, index) {
        final template = _favoriteTemplates[index];
        return _TemplateCard(
          template: template,
          onTap: () => _useTemplate(template),
          onLongPress: () => _showTemplateOptions(template),
        );
      },
    );
  }

  Widget _buildSuggestionsTab() {
    if (_suggestions.isEmpty) {
      return _buildEmptyState('暂无推荐', '使用模板后会自动生成推荐');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _SuggestionCard(
          suggestion: suggestion,
          onTap: () => _useTemplate(suggestion.template),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _useTemplate(SmartTemplate template) async {
    final repo = ref.read(smartTemplateRepositoryProvider);
    await repo.incrementUseCount(template.id!);
    _loadTemplates();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(template.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '使用模板: ${template.name} (${template.defaultDurationMinutes}分钟)',
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: '创建记录',
            onPressed: () => _createRecordFromTemplate(template),
          ),
        ),
      );
    }
  }

  void _createRecordFromTemplate(SmartTemplate template) {
    // Navigate to record form with template data pre-filled
    context.push(
      '/record/new?template=${template.id}&duration=${template.defaultDurationMinutes}',
    );
  }

  void _showTemplateOptions(SmartTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('使用模板'),
            onTap: () {
              Navigator.pop(ctx);
              _useTemplate(template);
            },
          ),
          ListTile(
            leading: Icon(
              template.isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            title: Text(template.isFavorite ? '取消收藏' : '收藏'),
            onTap: () async {
              Navigator.pop(ctx);
              final repo = ref.read(smartTemplateRepositoryProvider);
              await repo.toggleFavorite(template.id!);
              if (!ctx.mounted) return;
              _loadTemplates();
            },
          ),
        ],
      ),
    );
  }

  void _showAddTemplateDialog() {
    _showTemplateFormDialog();
  }

  void _showTemplateFormDialog({SmartTemplate? template}) {
    final nameController = TextEditingController(text: template?.name ?? '');
    final iconController = TextEditingController(text: template?.icon ?? '📌');
    final colorController = TextEditingController(text: template?.color ?? '#607D8B');
    final tagsController = TextEditingController(
      text: template?.defaultTags.join(', ') ?? '',
    );
    int duration = template?.defaultDurationMinutes ?? 30;
    String? selectedCategory = template?.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(template == null ? '创建模板' : '编辑模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '模板名称',
                    hintText: '例如：工作、学习',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: iconController,
                        decoration: const InputDecoration(
                          labelText: '图标',
                          hintText: '📌',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: colorController,
                        decoration: const InputDecoration(
                          labelText: '颜色',
                          hintText: '#607D8B',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('时长'),
                Slider(
                  value: duration.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '$duration 分钟',
                  onChanged: (v) => setDialogState(() => duration = v.toInt()),
                ),
                const SizedBox(height: 16),
                const Text('分类'),
                Wrap(
                  spacing: 8,
                  children: _categories.skip(1).map((cat) {
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedCategory = selected ? cat : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: '默认标签 (逗号分隔)',
                    hintText: '工作, 重要',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(smartTemplateRepositoryProvider);
                final newTemplate = SmartTemplate(
                  id: template?.id,
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  color: colorController.text.trim(),
                  category: selectedCategory,
                  defaultTags: tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  defaultDurationMinutes: duration,
                  isFavorite: template?.isFavorite ?? false,
                  useCount: template?.useCount ?? 0,
                  createdAt: template?.createdAt ?? DateTime.now(),
                );
                if (template == null) {
                  await repo.insertTemplate(newTemplate);
                } else {
                  await repo.updateTemplate(newTemplate);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadTemplates();
              },
              child: Text(template == null ? '创建' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAISuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'AI 智能推荐',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<TemplateSuggestion>>(
                future: ref.read(smartTemplateRepositoryProvider).getSuggestions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final suggestions = snapshot.data ?? [];
                  if (suggestions.isEmpty) {
                    return const Center(
                      child: Text('暂无推荐，请先使用一些模板'),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return _SuggestionCard(
                        suggestion: suggestion,
                        onTap: () {
                          Navigator.pop(ctx);
                          _useTemplate(suggestion.template);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final SmartTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(template.color.replaceFirst('#', '0xFF')),
    );

    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Text(template.icon, style: const TextStyle(fontSize: 36)),
                if (template.isFavorite)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${template.defaultDurationMinutes}分钟',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (template.useCount > 0)
              Text(
                '使用 ${template.useCount} 次',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final TemplateSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(suggestion.template.color.replaceFirst('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    suggestion.template.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          suggestion.template.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(suggestion.confidence * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '时长: ${suggestion.template.defaultDurationMinutes}分钟',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}