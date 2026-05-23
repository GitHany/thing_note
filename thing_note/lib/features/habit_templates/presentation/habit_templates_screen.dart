import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_templates/data/habit_templates_service.dart';

class HabitTemplatesScreen extends ConsumerStatefulWidget {
  const HabitTemplatesScreen({super.key});

  @override
  ConsumerState<HabitTemplatesScreen> createState() => _HabitTemplatesScreenState();
}

class _HabitTemplatesScreenState extends ConsumerState<HabitTemplatesScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final templatesAsync = _selectedCategory == 'all'
        ? ref.watch(habitTemplatesProvider)
        : ref.watch(habitTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯模板库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTemplateDialog(context),
            tooltip: '创建模板',
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类筛选
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: '全部',
                    isSelected: _selectedCategory == 'all',
                    onTap: () => setState(() => _selectedCategory = 'all'),
                  ),
                  _CategoryChip(
                    label: '健康',
                    icon: Icons.favorite,
                    isSelected: _selectedCategory == 'health',
                    onTap: () => setState(() => _selectedCategory = 'health'),
                  ),
                  _CategoryChip(
                    label: '学习',
                    icon: Icons.school,
                    isSelected: _selectedCategory == 'study',
                    onTap: () => setState(() => _selectedCategory = 'study'),
                  ),
                  _CategoryChip(
                    label: '工作',
                    icon: Icons.work,
                    isSelected: _selectedCategory == 'work',
                    onTap: () => setState(() => _selectedCategory = 'work'),
                  ),
                  _CategoryChip(
                    label: '社交',
                    icon: Icons.people,
                    isSelected: _selectedCategory == 'social',
                    onTap: () => setState(() => _selectedCategory = 'social'),
                  ),
                ],
              ),
            ),
          ),
          // 推荐模板
          if (_selectedCategory == 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥 推荐模板', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ref.watch(recommendedTemplatesProvider).when(
                      data: (templates) => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: templates.length,
                        itemBuilder: (context, index) => _RecommendedTemplateCard(
                          template: templates[index],
                          onTap: () => _createHabit(context, templates[index]),
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // 模板列表
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                final filtered = _selectedCategory == 'all'
                    ? templates
                    : templates.where((t) => t.category == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('暂无${_selectedCategory == 'all' ? '' : _getCategoryLabel(_selectedCategory)}模板'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _TemplateCard(
                    template: filtered[index],
                    onCreate: () => _createHabit(context, filtered[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'health':
        return '健康';
      case 'study':
        return '学习';
      case 'work':
        return '工作';
      case 'social':
        return '社交';
      default:
        return '';
    }
  }

  void _createHabit(BuildContext context, HabitTemplate template) async {
    final service = ref.read(habitTemplatesServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await service.createHabitFromTemplate(template);
    ref.invalidate(habitTemplatesProvider);

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('已创建习惯: ${template.name}')),
    );
  }

  void _showAddTemplateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'health';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建习惯模板'),
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
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: '分类'),
                items: const [
                  DropdownMenuItem(value: 'health', child: Text('健康')),
                  DropdownMenuItem(value: 'study', child: Text('学习')),
                  DropdownMenuItem(value: 'work', child: Text('工作')),
                  DropdownMenuItem(value: 'social', child: Text('社交')),
                ],
                onChanged: (value) => setState(() => category = value!),
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
                  final service = ref.read(habitTemplatesServiceProvider);
                  await service.addTemplate(HabitTemplate(
                    name: nameController.text,
                    description: descController.text.isNotEmpty ? descController.text : null,
                    category: category,
                  ));
                  ref.invalidate(habitTemplatesProvider);
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 16) : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _RecommendedTemplateCard extends StatelessWidget {
  final HabitTemplate template;
  final VoidCallback onTap;

  const _RecommendedTemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 14, color: Colors.green),
                  Text(' ${(template.successRate * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final HabitTemplate template;
  final VoidCallback onCreate;

  const _TemplateCard({required this.template, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getCategoryIcon(template.category), color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (template.description != null)
                    Text(template.description!, style: TextStyle(color: Colors.grey[600]), maxLines: 1),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(template.frequency, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${template.useCount} 人使用', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onCreate,
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'health':
        return Icons.favorite;
      case 'study':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'social':
        return Icons.people;
      default:
        return Icons.auto_awesome;
    }
  }
}