import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_notification_timing/data/timing_provider.dart';
import 'package:thing_note/features/smart_notification_timing/domain/timing_model.dart';

class SmartNotificationTimingScreen extends ConsumerWidget {
  const SmartNotificationTimingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(timingNotifierProvider);
    final statsAsync = ref.watch(timingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能通知时机'),
      ),
      body: Column(
        children: [
          // Stats Overview
          statsAsync.when(
            data: (stats) => _buildStatsCard(context, stats),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Rules List
          Expanded(
            child: rulesAsync.when(
              data: (rules) => _buildRulesList(context, rules, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRuleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加规则'),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, TimingStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.teal.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('规则数', '${stats.totalRules}', Icons.rule),
          _buildStatItem('平均响应', '${(stats.averageResponseRate * 100).toInt()}%', Icons.trending_up),
          _buildStatItem('最佳时机', stats.bestTiming, Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRulesList(BuildContext context, List<NotificationTimingRule> rules, WidgetRef ref) {
    if (rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无通知规则',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '添加规则优化通知时机',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return _buildRuleCard(context, rule, ref);
      },
    );
  }

  Widget _buildRuleCard(BuildContext context, NotificationTimingRule rule, WidgetRef ref) {
    final timeStr = rule.optimalHour != null
        ? '${rule.optimalHour!.toString().padLeft(2, '0')}:${(rule.optimalMinute ?? 0).toString().padLeft(2, '0')}'
        : '未设置';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.2),
          child: const Icon(Icons.notifications, color: Colors.teal),
        ),
        title: Text(rule.notificationType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最佳时机: $timeStr'),
            Text(
              '响应率: ${(rule.responseRate * 100).toInt()}% (${rule.sampleCount} 样本)',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rule.responseRate > 0.7
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rule.responseRate > 0.7 ? '优秀' : '待优化',
                style: TextStyle(
                  color: rule.responseRate > 0.7 ? Colors.green : Colors.orange,
                  fontSize: 11,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(timingNotifierProvider.notifier).deleteRule(rule.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    final types = ['习惯提醒', '目标提醒', '周回顾', '每日摘要'];
    String selectedType = types.first;
    int selectedHour = 9;
    int selectedMinute = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加通知规则'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: '通知类型',
                  border: OutlineInputBorder(),
                ),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('最佳时机: '),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedHour,
                    items: List.generate(24, (i) => i)
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h')))
                        .toList(),
                    onChanged: (v) => setState(() => selectedHour = v!),
                  ),
                  const Text(' : '),
                  DropdownButton<int>(
                    value: selectedMinute,
                    items: [0, 15, 30, 45]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) => setState(() => selectedMinute = v!),
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
                ref.read(timingNotifierProvider.notifier).addRule(
                  selectedType,
                  selectedHour,
                  selectedMinute,
                );
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}