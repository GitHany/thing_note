import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TemplateMarketScreen extends ConsumerStatefulWidget {
  const TemplateMarketScreen({super.key});

  @override
  ConsumerState<TemplateMarketScreen> createState() => _TemplateMarketScreenState();
}

class _TemplateMarketScreenState extends ConsumerState<TemplateMarketScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模板市场'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildTemplateGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTemplateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['全部', '工作', '学习', '运动', '健康', '娱乐', '社交'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = (_selectedCategory == 'all' && category == '全部') ||
              _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category == '全部' ? 'all' : category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateGrid() {
    final templates = _getTemplates();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.description,
                    color: Color(int.parse(template['color'].toString().replaceFirst('#', '0xFF'))),
                    size: 32,
                  ),
                  IconButton(
                    icon: Icon(
                      template['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                      color: template['isFavorite'] ? Colors.red : null,
                    ),
                    onPressed: () {
                      setState(() {
                        template['isFavorite'] = !template['isFavorite'];
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${template['defaultDuration']} 分钟',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '使用 ${template['useCount']} 次',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTemplates() {
    return [
      {'name': '每日站会', 'category': '工作', 'description': '快速记录每日工作进度', 'color': '#2196F3', 'defaultDuration': 15, 'useCount': 156, 'isFavorite': true},
      {'name': '健身记录', 'category': '运动', 'description': '记录运动和体能数据', 'color': '#4CAF50', 'defaultDuration': 30, 'useCount': 89, 'isFavorite': false},
      {'name': '学习笔记', 'category': '学习', 'description': '记录学习内容和要点', 'color': '#9C27B0', 'defaultDuration': 45, 'useCount': 234, 'isFavorite': true},
      {'name': '用餐记录', 'category': '健康', 'description': '记录饮食情况', 'color': '#FF9800', 'defaultDuration': 5, 'useCount': 312, 'isFavorite': false},
      {'name': '会议纪要', 'category': '工作', 'description': '记录会议讨论和决策', 'color': '#607D8B', 'defaultDuration': 60, 'useCount': 78, 'isFavorite': false},
      {'name': '读书笔记', 'category': '学习', 'description': '记录阅读心得和摘录', 'color': '#795548', 'defaultDuration': 30, 'useCount': 145, 'isFavorite': true},
      {'name': '冥想记录', 'category': '健康', 'description': '记录冥想和放松时间', 'color': '#00BCD4', 'defaultDuration': 20, 'useCount': 67, 'isFavorite': false},
      {'name': '社交活动', 'category': '社交', 'description': '记录社交互动和感想', 'color': '#E91E63', 'defaultDuration': 30, 'useCount': 92, 'isFavorite': false},
    ];
  }

  void _useTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('使用模板: ${template['name']}')),
    );
    context.go('/record/new');
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建模板'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '模板名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '模板描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: ['工作', '学习', '运动', '健康', '娱乐', '社交']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模板创建成功')),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}