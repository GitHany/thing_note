import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_stacking/data/habit_stacking_provider.dart';
import 'package:thing_note/features/habit_stacking/domain/habit_stacking.dart';

class HabitStackingScreen extends ConsumerWidget {
  const HabitStackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainsAsync = ref.watch(habitChainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯堆叠'),
      ),
      body: chainsAsync.when(
        data: (chains) => chains.isEmpty
            ? _buildEmptyState(context, ref)
            : _buildChainsList(context, ref, chains),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChainDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('创建链'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link, size: 64, color: Colors.teal.shade300),
          const SizedBox(height: 16),
          const Text('还没有习惯链'),
          const SizedBox(height: 8),
          const Text('习惯堆叠是一种将新习惯\n与已有习惯绑定的技巧'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddChainDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('创建第一个链'),
          ),
        ],
      ),
    );
  }

  Widget _buildChainsList(BuildContext context, WidgetRef ref, List<HabitChain> chains) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chains.length,
      itemBuilder: (context, index) {
        final chain = chains[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      chain.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (chain.streak > 0)
                      Chip(
                        avatar: const Icon(Icons.local_fire_department, size: 16),
                        label: Text('${chain.streak}天'),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...chain.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.habit)),
                      Text(
                        '${item.durationMinutes}分钟',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '总时长: ${chain.items.fold<int>(0, (sum, item) => sum + item.durationMinutes)}分钟',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Start chain
                      },
                      child: const Text('开始'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddChainDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final habits = <String>[];
    final habitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建习惯链'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '链名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: habitController,
                  decoration: InputDecoration(
                    labelText: '添加习惯',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (habitController.text.isNotEmpty) {
                          setState(() {
                            habits.add(habitController.text);
                            habitController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...habits.asMap().entries.map((entry) => ListTile(
                  leading: Text('${entry.key + 1}'),
                  title: Text(entry.value),
                )),
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
                if (nameController.text.isNotEmpty && habits.isNotEmpty) {
                  final chain = HabitChain(
                    name: nameController.text,
                    items: habits.map((h) => HabitStackItem(habit: h)).toList(),
                  );
                  ref.read(habitStackingServiceProvider).addChain(chain);
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