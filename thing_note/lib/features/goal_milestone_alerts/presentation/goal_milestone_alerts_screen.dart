import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/goal_milestone_alerts/data/goal_milestone_repository.dart';
import 'package:thing_note/features/goal_milestone_alerts/domain/goal_milestone.dart';

final milestonesProvider = FutureProvider<List<GoalMilestone>>((ref) async {
  final repository = ref.watch(goalMilestoneRepositoryProvider);
  return repository.getAllMilestones();
});

final uncelebratedProvider = FutureProvider<List<GoalMilestone>>((ref) async {
  final repository = ref.watch(goalMilestoneRepositoryProvider);
  return repository.getUncelebratedMilestones();
});

class GoalMilestoneAlertsScreen extends ConsumerWidget {
  const GoalMilestoneAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uncelebratedAsync = ref.watch(uncelebratedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标里程碑提醒'),
      ),
      body: uncelebratedAsync.when(
        data: (milestones) {
          if (milestones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  const Text('暂无待庆祝的里程碑'),
                  const SizedBox(height: 8),
                  const Text('继续努力达成你的目标吧！'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: milestones.length,
            itemBuilder: (context, index) => _buildMilestoneCard(context, ref, milestones[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildMilestoneCard(BuildContext context, WidgetRef ref, GoalMilestone milestone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity( 0.1),
              Colors.orange.withOpacity( 0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '目标 #${milestone.goalId}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          milestone.milestoneLabel,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${milestone.milestoneValue.toInt()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _celebrateMilestone(context, ref, milestone),
                      icon: const Icon(Icons.celebration),
                      label: const Text('庆祝'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareMilestone(context, milestone),
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _celebrateMilestone(BuildContext context, WidgetRef ref, GoalMilestone milestone) async {
    final repository = ref.read(goalMilestoneRepositoryProvider);
    await repository.markAsCelebrated(milestone.id!);
    ref.invalidate(uncelebratedProvider);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.amber),
              SizedBox(width: 8),
              Text('🎉 恭喜！'),
            ],
          ),
          content: const Text('你已达成重要里程碑！继续保持，向着下一个目标前进！'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('继续努力'),
            ),
          ],
        ),
      );
    }
  }

  void _shareMilestone(BuildContext context, GoalMilestone milestone) {
    final text = '🎉 我在 thing_note 达成目标里程碑：${milestone.milestoneLabel} (${milestone.milestoneValue.toInt()}%)！';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: $text')),
    );
  }
}