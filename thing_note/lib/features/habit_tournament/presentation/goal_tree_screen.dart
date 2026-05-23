import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_tournament/data/tournament_repository.dart';
import 'package:thing_note/features/habit_tournament/domain/tournament_models.dart';

class GoalTreeScreen extends ConsumerStatefulWidget {
  const GoalTreeScreen({super.key});

  @override
  ConsumerState<GoalTreeScreen> createState() => _GoalTreeScreenState();
}

class _GoalTreeScreenState extends ConsumerState<GoalTreeScreen> {
  @override
  Widget build(BuildContext context) {
    final treesAsync = ref.watch(goalTreesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标树'),
      ),
      body: treesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (trees) {
          if (trees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无目标树', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('创建目标树，将大目标分解为小目标', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('创建目标树'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trees.length,
            itemBuilder: (context, index) {
              return _GoalTreeCard(
                tree: trees[index],
                onDelete: () => ref.read(goalTreesProvider.notifier).deleteTree(trees[index].id!),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建目标树'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final tree = GoalTree(
                  name: nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  createdAt: DateTime.now(),
                );
                ref.read(goalTreesProvider.notifier).addTree(tree);
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _GoalTreeCard extends StatelessWidget {
  final GoalTree tree;
  final VoidCallback onDelete;

  const _GoalTreeCard({required this.tree, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_tree, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tree.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (tree.description != null)
                          Text(tree.description!, style: TextStyle(color: Colors.grey[600]), maxLines: 2),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '创建于 ${tree.createdAt.month}/${tree.createdAt.day}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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