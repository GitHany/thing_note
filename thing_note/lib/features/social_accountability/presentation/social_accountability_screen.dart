import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/social_accountability/data/social_accountability_repository.dart';
import 'package:thing_note/features/social_accountability/domain/accountability.dart';

class SocialAccountabilityScreen extends ConsumerWidget {
  const SocialAccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(accountabilityGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('社交问责'),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('错误: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_add, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无问责组', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('与朋友分享目标，互相督促', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('创建问责组'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(group: group);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建问责组'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '组名称'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('匿名模式'),
                subtitle: const Text('只分享进度，不透露具体内容'),
                value: isAnonymous,
                onChanged: (v) => setState(() => isAnonymous = v),
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
                if (nameController.text.isNotEmpty) {
                  final group = AccountabilityGroup(
                    groupName: nameController.text,
                    isAnonymous: isAnonymous ? 1 : 0,
                  );
                  ref.read(accountabilityGroupsProvider.notifier).addGroup(group);
                  Navigator.pop(context);
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

class _GroupCard extends ConsumerWidget {
  final AccountabilityGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(groupUpdatesProvider(group.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.groupName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (group.isAnonymous == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('匿名', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('最近更新:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            updatesAsync.when(
              data: (updates) {
                if (updates.isEmpty) {
                  return const Text('暂无更新', style: TextStyle(color: Colors.grey));
                }
                return Column(
                  children: updates.take(3).map((u) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          u.isEncouragement == 1 ? '💪' : '📝',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            u.progressNote ?? '进展更新',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('错误: $e'),
            ),
          ],
        ),
      ),
    );
  }
}