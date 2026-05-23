import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/timeboxing_assistant/data/timeboxing_assistant_repository.dart';
import 'package:thing_note/features/timeboxing_assistant/domain/time_block_plan.dart';

class TimeboxingAssistantScreen extends ConsumerStatefulWidget {
  const TimeboxingAssistantScreen({super.key});

  @override
  ConsumerState<TimeboxingAssistantScreen> createState() => _TimeboxingAssistantScreenState();
}

class _TimeboxingAssistantScreenState extends ConsumerState<TimeboxingAssistantScreen> {
  final List<_ActivityInput> _activities = [];

  @override
  void initState() {
    super.initState();
    _addActivity();
  }

  void _addActivity() {
    setState(() {
      _activities.add(_ActivityInput());
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(timeBlockPlansProvider);
    final todayPlanAsync = ref.watch(todayPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 时间规划'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayCard(todayPlanAsync),
            const SizedBox(height: 24),
            _buildActivityInput(),
            const SizedBox(height: 24),
            _buildHistory(plansAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(AsyncValue<TimeBlockPlan?> todayPlanAsync) {
    return todayPlanAsync.when(
      data: (plan) {
        if (plan == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text(
                  '今日时间规划',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '添加活动，让 AI 帮你规划',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.today, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Text('今日时间块', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (plan.isAccepted == 1)
                    const Chip(label: Text('已采纳'), backgroundColor: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              ...plan.suggestedBlockList.map((block) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(TimeBlock.typeColors[block.type] ?? 0xFF2196F3).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${block.startHour}:00',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        block.activity.isEmpty
                            ? TimeBlock.typeLabels[block.type] ?? block.type
                            : block.activity,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${block.duration}h',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
              if (plan.efficiencyScore > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '效率评分: ${(plan.efficiencyScore * 100).toInt()}%',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('错误: $e'),
    );
  }

  Widget _buildActivityInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_note, color: Colors.blue),
                SizedBox(width: 8),
                Text('添加活动', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ..._activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: activity.controller,
                        decoration: InputDecoration(
                          hintText: '活动 ${index + 1}',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: activity.durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '时长',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('h', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addActivity,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _generatePlan,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI 生成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(AsyncValue<List<TimeBlockPlan>> plansAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('历史规划', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return const Text('暂无历史记录', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: plans.take(5).map((plan) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(plan.planDate),
                    subtitle: Text('${plan.suggestedBlockList.length} 个时间块'),
                    trailing: plan.isAccepted == 1
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('错误: $e'),
        ),
      ],
    );
  }

  void _generatePlan() {
    final activities = <String>[];
    final durations = <int>[];

    for (final activity in _activities) {
      if (activity.controller.text.isNotEmpty) {
        activities.add(activity.controller.text);
        durations.add(int.tryParse(activity.durationController.text) ?? 1);
      }
    }

    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个活动')),
      );
      return;
    }

    ref.read(timeBlockPlansProvider.notifier).generatePlan(
      DateTime.now(),
      activities,
      durations,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('时间块已生成')),
    );
  }
}

class _ActivityInput {
  final TextEditingController controller = TextEditingController();
  final TextEditingController durationController = TextEditingController(text: '1');
}