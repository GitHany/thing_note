import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_reset/data/habit_reset_repository.dart';
import 'package:thing_note/features/habit_reset/domain/habit_reset.dart';

class HabitResetScreen extends ConsumerWidget {
  const HabitResetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final resetsAsync = ref.watch(habitResetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯重置'),
      ),
      body: Column(
        children: [
          _buildExplanation(),
          Expanded(
            child: resetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误: $e')),
              data: (resets) {
                if (resets.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无重置记录', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('当习惯中断后，可以选择重置', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resets.length,
                  itemBuilder: (context, index) {
                    final reset = resets[index];
                    return _ResetCard(reset: reset);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('关于习惯重置', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '软重置：保留历史记录，连续天数归零，重新开始\n'
            '硬重置：清除所有历史，从头开始\n\n'
            '重置不等于放弃，而是为了更好地重新出发。',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ResetCard extends ConsumerWidget {
  final HabitReset reset;

  const _ResetCard({required this.reset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: reset.isSoftReset == 1 ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            reset.isSoftReset == 1 ? Icons.undo : Icons.delete_forever,
            color: reset.isSoftReset == 1 ? Colors.orange : Colors.red,
          ),
        ),
        title: Text('习惯 #${reset.habitId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('原因: ${HabitReset.reasonLabels[reset.resetReason] ?? reset.resetReason}'),
            Text(
              '${reset.previousStreak} 天 → 0 天',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '${DateTime.parse(reset.resetDate).month}/${DateTime.parse(reset.resetDate).day}',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}