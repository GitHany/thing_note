import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickRecordTemplateProvider = StateNotifierProvider<QuickRecordTemplateNotifier, List<Map<String, dynamic>>>((ref) {
  return QuickRecordTemplateNotifier();
});

class QuickRecordTemplateNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  QuickRecordTemplateNotifier() : super([
    {'id': 1, 'name': '工作', 'icon': '💼', 'color': '#2196F3', 'count': 28},
    {'id': 2, 'name': '学习', 'icon': '📚', 'color': '#4CAF50', 'count': 15},
    {'id': 3, 'name': '运动', 'icon': '🏃', 'color': '#FF9800', 'count': 12},
    {'id': 4, 'name': '健康', 'icon': '💪', 'color': '#E91E63', 'count': 8},
  ]);

  void addTemplate(Map<String, dynamic> template) {}
  void deleteTemplate(int id) {}
}

class QuickRecordTemplateScreen extends ConsumerWidget {
  const QuickRecordTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(quickRecordTemplateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷记录模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTemplate(context),
          ),
        ],
      ),
      body: templates.isEmpty
          ? _buildEmptyState(context)
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateCard(
                  template: template,
                  onTap: () => _useTemplate(context, template),
                  onDelete: () => ref.read(quickRecordTemplateProvider.notifier).deleteTemplate(template['id'] as int),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.copy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无模板', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建快速记录模板，一键创建记录', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addTemplate(context),
            icon: const Icon(Icons.add),
            label: const Text('创建模板'),
          ),
        ],
      ),
    );
  }

  void _addTemplate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建模板'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: '模板名称'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: '图标 (emoji)'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: '默认标签 (逗号分隔)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _useTemplate(BuildContext context, Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('使用模板 "${template['name']}" 创建记录...')),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = template['name'] as String;
    final icon = template['icon'] as String;
    final color = Color(int.parse(template['color']?.replaceFirst('#', '0xFF') ?? '0xFF607D8B'));
    final count = template['count'] as int;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '已使用 $count 次',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}