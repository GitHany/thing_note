import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/monthly_milestones/data/milestones_repository.dart';
import 'package:thing_note/features/monthly_milestones/domain/monthly_milestone.dart';

class MonthlyMilestonesScreen extends ConsumerWidget {
  const MonthlyMilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(currentMonthMilestonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('月度里程碑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: milestonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (milestones) => _buildContent(context, milestones),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MonthlyMilestone> milestones) {
    final now = DateTime.now();
    final monthName = _monthName(now.month);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$monthName ${now.year}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${milestones.where((m) => m.isCompleted).length}/${milestones.length} 完成',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '设定本月的目标和里程碑',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (milestones.isEmpty)
            const _EmptyState()
          else
            ...milestones.map((m) => _MilestoneCard(milestone: m)),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '1');
    String targetType = 'count';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建里程碑'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '里程碑标题')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述 (可选)'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标值')),
              const SizedBox(height: 8),
              const Text('目标类型:'),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('次数'), selected: targetType == 'count', onSelected: (_) => targetType = 'count'),
                  ChoiceChip(label: const Text('天数'), selected: targetType == 'streak', onSelected: (_) => targetType = 'streak'),
                  ChoiceChip(label: const Text('时长'), selected: targetType == 'duration', onSelected: (_) => targetType = 'duration'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final now = DateTime.now();
              final milestone = MonthlyMilestone(
                year: now.year,
                month: now.month,
                milestoneTitle: titleCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                targetValue: double.tryParse(targetCtrl.text) ?? 1,
                targetType: targetType,
                createdAt: now,
              );
              ref.read(milestonesRepositoryProvider).insertMilestone(milestone);
              ref.invalidate(currentMonthMilestonesProvider);
              Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
    return months[month - 1];
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 48),
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('本月暂无里程碑', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('设定目标，保持前进动力', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MonthlyMilestone milestone;
  const _MilestoneCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final progress = milestone.progressPercent;
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
                  milestone.isCompleted ? Icons.check_circle : Icons.flag,
                  color: milestone.isCompleted ? Colors.green : Color(milestone.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    milestone.milestoneTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (milestone.isCompleted)
                  const Icon(Icons.check, color: Colors.green, size: 20),
              ],
            ),
            if (milestone.description != null) ...[
              const SizedBox(height: 4),
              Text(milestone.description!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(Color(milestone.color)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${milestone.currentValue.toInt()}/${milestone.targetValue.toInt()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% 完成',
              style: TextStyle(fontSize: 12, color: milestone.isCompleted ? Colors.green : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
