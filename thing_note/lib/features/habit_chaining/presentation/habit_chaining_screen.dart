import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_chaining/data/habit_chain_provider.dart';
import 'package:thing_note/features/habit_chaining/domain/habit_chain_model.dart';

class HabitChainingScreen extends ConsumerWidget {
  const HabitChainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainsAsync = ref.watch(habitChainNotifierProvider);
    final recommendationsAsync = ref.watch(chainRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯链条建议'),
      ),
      body: Column(
        children: [
          // Recommendations Section
          recommendationsAsync.when(
            data: (recs) => _buildRecommendations(context, recs),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Chains List
          Expanded(
            child: chainsAsync.when(
              data: (chains) => _buildChainsList(context, chains, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChainDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('创建链条'),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, List<ChainRecommendation> recs) {
    if (recs.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '智能推荐',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recs.take(2).map((rec) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                rec.chainType == 'time' ? Icons.schedule : Icons.location_on,
                color: Colors.blue,
              ),
              title: Text('习惯 #${rec.habitId} → #${rec.suggestedNextHabitId}'),
              subtitle: Text(rec.reason),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(rec.confidence * 100).toInt()}%',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChainsList(BuildContext context, List<HabitChain> chains, WidgetRef ref) {
    if (chains.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无习惯链条',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '创建链条将习惯链接起来',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chains.length,
      itemBuilder: (context, index) {
        final chain = chains[index];
        return _buildChainCard(context, chain, ref);
      },
    );
  }

  Widget _buildChainCard(BuildContext context, HabitChain chain, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  chain.chainType == 'time' ? Icons.schedule : Icons.location_on,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chain.chainName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${chain.completionCount} 次完成',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Visual chain representation
            Row(
              children: chain.habitIds.take(5).map((habitId) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#$habitId',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '成功率: ${(chain.successRate * 100).toInt()}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(habitChainNotifierProvider.notifier).recordChainCompletion(chain.id),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('完成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChainDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String chainType = 'time';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建习惯链条'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '链条名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('类型: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('时间链'),
                    selected: chainType == 'time',
                    onSelected: (selected) {
                      if (selected) setState(() => chainType = 'time');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('地点链'),
                    selected: chainType == 'location',
                    onSelected: (selected) {
                      if (selected) setState(() => chainType = 'location');
                    },
                  ),
                ],
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
                  ref.read(habitChainNotifierProvider.notifier).addChain(
                    nameController.text,
                    [1, 2, 3], // 示例数据
                    chainType,
                  );
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