import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_tournament/data/tournament_repository.dart';
import 'package:thing_note/features/habit_tournament/domain/tournament_models.dart';

class ReminderPatternsScreen extends ConsumerWidget {
  const ReminderPatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(reminderPatternsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('提醒模式'),
      ),
      body: patternsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (patterns) {
          if (patterns.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pattern, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无提醒模式', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('系统会自动学习你的提醒习惯', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '基于你的提醒历史分析',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '显示你设置提醒的时间模式，帮助你优化提醒策略',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...patterns.map((p) => _PatternCard(pattern: p)),
            ],
          );
        },
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final ReminderPattern pattern;

  const _PatternCard({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(pattern.patternType), color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTypeLabel(pattern.patternType),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _SuccessRateBadge(rate: pattern.successRate),
              ],
            ),
            const SizedBox(height: 12),
            if (pattern.triggerTime != null)
              _InfoRow(icon: Icons.access_time, label: '触发时间', value: pattern.triggerTime!),
            if (pattern.triggerDays != null)
              _InfoRow(icon: Icons.date_range, label: '触发日期', value: pattern.triggerDays!),
            _InfoRow(icon: Icons.repeat, label: '总触发次数', value: '${pattern.totalTriggers}次'),
            if (pattern.lastTriggered != null)
              _InfoRow(
                icon: Icons.history,
                label: '上次触发',
                value: '${pattern.lastTriggered!.month}/${pattern.lastTriggered!.day} ${pattern.lastTriggered!.hour}:${pattern.lastTriggered!.minute.toString().padLeft(2, '0')}',
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.view_week;
      case 'custom':
        return Icons.settings;
      default:
        return Icons.alarm;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'daily':
        return '每日提醒';
      case 'weekly':
        return '每周提醒';
      case 'custom':
        return '自定义模式';
      default:
        return '提醒模式';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SuccessRateBadge extends StatelessWidget {
  final double rate;

  const _SuccessRateBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (rate >= 0.8) {
      color = Colors.green;
    } else if (rate >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(rate * 100).toStringAsFixed(0)}%',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}