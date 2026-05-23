import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/tag_hierarchy/domain/tag_hierarchy.dart';

class TagHierarchyScreen extends ConsumerStatefulWidget {
  const TagHierarchyScreen({super.key});

  @override
  ConsumerState<TagHierarchyScreen> createState() => _TagHierarchyScreenState();
}

class _TagHierarchyScreenState extends ConsumerState<TagHierarchyScreen> {
  @override
  Widget build(BuildContext context) {
    final tagTreeAsync = ref.watch(tagTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签层级管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: tagTreeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (tagTree) {
          if (tagTree.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.label_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有标签'),
                  SizedBox(height: 8),
                  Text('点击右上角添加标签'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tagTree.length,
            itemBuilder: (context, index) {
              return _TagTreeItem(tag: tagTree[index]);
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddTagDialog(),
    );
  }
}

class _TagTreeItem extends StatelessWidget {
  final TagWithHierarchy tag;

  const _TagTreeItem({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: tag.level * 24.0),
          child: Card(
            child: ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(tag.name),
              subtitle: tag.children.isNotEmpty 
                  ? Text('${tag.children.length} 个子标签')
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editTag(context, tag),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addChildTag(context, tag),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (tag.children.isNotEmpty)
          ...tag.children.map((child) => _TagTreeItem(tag: child)),
      ],
    );
  }

  void _editTag(BuildContext context, TagWithHierarchy tag) {
    // TODO: Edit tag
  }

  void _addChildTag(BuildContext context, TagWithHierarchy tag) {
    // TODO: Add child tag
  }
}

class _AddTagDialog extends StatefulWidget {
  const _AddTagDialog();

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = '#607D8B';

  final List<String> _colors = [
    '#607D8B', '#2196F3', '#4CAF50', '#FF9800',
    '#F44336', '#9C27B0', '#00BCD4', '#795548',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加标签'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '标签名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('选择颜色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
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
            // TODO: Save tag
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}