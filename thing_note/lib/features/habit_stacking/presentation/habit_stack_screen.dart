import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_stacking/data/habit_stack_provider.dart';
import 'package:thing_note/features/habit_stacking/domain/habit_stack_models.dart';

class HabitStackScreen extends ConsumerStatefulWidget {
  const HabitStackScreen({super.key});

  @override
  ConsumerState<HabitStackScreen> createState() => _HabitStackScreenState();
}

class _HabitStackScreenState extends ConsumerState<HabitStackScreen> {
  @override
  Widget build(BuildContext context) {
    final stacksAsync = ref.watch(habitStacksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯堆叠'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: stacksAsync.when(
        data: (stacks) {
          if (stacks.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(habitStacksProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stacks.length,
              itemBuilder: (context, index) {
                return _StackCard(stackWithLinks: stacks[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStackDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('创建习惯链'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有习惯链',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '将多个小习惯链接在一起，形成强大的习惯链',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateStackDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('创建第一个习惯链'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('什么是习惯堆叠？'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '习惯堆叠是一种将多个小习惯链接在一起的技术。'
                '通过把新习惯与已有习惯绑定，你可以更容易地建立新的行为模式。\n',
              ),
              Text(
                '示例：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• 喝咖啡 → 写日记\n'
                '• 起床 → 拉伸 → 冥想\n'
                '• 刷牙 → 记录待办事项\n',
              ),
              Text(
                '每个习惯完成后会自动提醒你下一个习惯，'
                '帮助形成连贯的行动流程。',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('明白了'),
          ),
        ],
      ),
    );
  }

  void _showCreateStackDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int selectedColor = 0xFF2196F3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建习惯链'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '习惯链名称',
                  hintText: '例如：晨间习惯',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Wrap(
                  spacing: 8,
                  children: [
                    0xFF2196F3,
                    0xFF4CAF50,
                    0xFFFF9800,
                    0xFF9C27B0,
                    0xFFE91E63,
                    0xFF00BCD4,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
              if (nameController.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              final stack = HabitStack(
                name: nameController.text,
                description: descController.text.isEmpty ? null : descController.text,
                color: selectedColor,
              );
              await db.insert('habit_stacks', stack.toMap());
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(habitStacksProvider);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _StackCard extends ConsumerWidget {
  final HabitStackWithLinks stackWithLinks;

  const _StackCard({required this.stackWithLinks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = stackWithLinks.stack;
    final links = stackWithLinks.links;
    final habitNames = stackWithLinks.habitNames;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(stack.color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stack.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stack.description != null)
                        Text(
                          stack.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: stack.isActive,
                  onChanged: (value) async {
                    final db = await ref.read(databaseProvider.future);
                    await db.update(
                      'habit_stacks',
                      {'is_active': value ? 1 : 0},
                      where: 'id = ?',
                      whereArgs: [stack.id],
                    );
                    ref.invalidate(habitStacksProvider);
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context, ref, stack);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref, stack);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
            if (habitNames.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                '习惯链',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: habitNames.asMap().entries.map((entry) {
                  final index = entry.key;
                  final name = entry.value;
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(stack.color),
                      radius: 12,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                    label: Text(name),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: links.isNotEmpty
                        ? () async {
                            final db = await ref.read(databaseProvider.future);
                            await db.delete(
                              'stack_links',
                              where: 'id = ?',
                              whereArgs: [links[index].id],
                            );
                            ref.invalidate(habitStacksProvider);
                          }
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddHabitDialog(context, ref, stack.id!),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加习惯'),
              ),
            ] else ...[
              const Divider(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showAddHabitDialog(context, ref, stack.id!),
                  icon: const Icon(Icons.add),
                  label: const Text('添加第一个习惯'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, HabitStack stack) {
    final nameController = TextEditingController(text: stack.name);
    final descController = TextEditingController(text: stack.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑习惯链'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
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
              final db = await ref.read(databaseProvider.future);
              await db.update(
                'habit_stacks',
                {
                  'name': nameController.text,
                  'description': descController.text.isEmpty ? null : descController.text,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [stack.id],
              );
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(habitStacksProvider);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, HabitStack stack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除习惯链'),
        content: Text('确定要删除 "${stack.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.delete('stack_links', where: 'stack_id = ?', whereArgs: [stack.id]);
              await db.delete('habit_stacks', where: 'id = ?', whereArgs: [stack.id]);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(habitStacksProvider);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref, int stackId) async {
    final db = await ref.read(databaseProvider.future);
    final habits = await db.query('habits', orderBy: 'created_at DESC');
    
    if (habits.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建习惯')),
      );
      return;
    }

    int? selectedHabitId;
    
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加习惯到链'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isSelected = selectedHabitId == habit['id'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Color(stackWithLinks.stack.color) : Colors.grey,
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(habit['name'] as String),
                  selected: isSelected,
                  onTap: () => setState(() => selectedHabitId = habit['id'] as int?),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: selectedHabitId == null
                  ? null
                  : () async {
                      final existingLinks = await db.query(
                        'stack_links',
                        where: 'stack_id = ?',
                        whereArgs: [stackId],
                      );
                      
                      await db.insert('stack_links', {
                        'stack_id': stackId,
                        'habit_id': selectedHabitId,
                        'order_index': existingLinks.length,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.invalidate(habitStacksProvider);
                      }
                    },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}