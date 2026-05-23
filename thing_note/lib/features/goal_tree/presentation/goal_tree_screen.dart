import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalTreeProvider = StateNotifierProvider<GoalTreeNotifier, List<Map<String, dynamic>>>((ref) {
  return GoalTreeNotifier();
});

class GoalTreeNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  GoalTreeNotifier() : super([
    {
      'id': 1,
      'title': '2024年目标',
      'children': [
        {'id': 2, 'title': '健康目标', 'children': [
          {'id': 3, 'title': '每周运动3次'},
          {'id': 4, 'title': '早睡早起'},
        ]},
        {'id': 5, 'title': '学习目标', 'children': [
          {'id': 6, 'title': '读完10本书'},
          {'id': 7, 'title': '学习新技术'},
        ]},
      ],
    },
  ]);

  void addChild(int parentId, Map<String, dynamic> child) {}
  void removeNode(int id) {}
}

class GoalTreeScreen extends ConsumerWidget {
  const GoalTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trees = ref.watch(goalTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标树'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTree(context),
          ),
        ],
      ),
      body: trees.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trees.length,
              itemBuilder: (context, index) {
                final tree = trees[index];
                return _TreeCard(tree: tree);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_tree, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无目标树', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建目标树来分解你的目标', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addTree(context),
            icon: const Icon(Icons.add),
            label: const Text('创建目标树'),
          ),
        ],
      ),
    );
  }

  void _addTree(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建目标树'),
        content: const TextField(
          decoration: InputDecoration(labelText: '目标树名称'),
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
}

class _TreeCard extends StatefulWidget {
  final Map<String, dynamic> tree;

  const _TreeCard({required this.tree});

  @override
  State<_TreeCard> createState() => _TreeCardState();
}

class _TreeCardState extends State<_TreeCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final title = widget.tree['title'] as String;
    final children = widget.tree['children'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_tree, color: Colors.blue),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addChild(context),
                ),
              ],
            ),
          ),
          if (_expanded && children.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: children.map((child) => _TreeNode(
                  node: child,
                  depth: 1,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _addChild(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加子目标'),
        content: const TextField(
          decoration: InputDecoration(labelText: '目标名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _TreeNode extends StatelessWidget {
  final Map<String, dynamic> node;
  final int depth;

  const _TreeNode({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    final title = node['title'] as String;
    final children = node['children'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: depth * 24.0),
            const Icon(Icons.subdirectory_arrow_right, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ...children.map((child) => _TreeNode(node: child, depth: depth + 1)),
      ],
    );
  }
}