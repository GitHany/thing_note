import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/smart_daily_brief.dart';

/// 智能日报屏幕
class SmartDailyBriefScreen extends ConsumerWidget {
  const SmartDailyBriefScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefAsync = ref.watch(smartDailyBriefProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能日报'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(smartDailyBriefProvider.notifier).generateBrief(DateTime.now().toIso8601String().split('T')[0]),
          ),
        ],
      ),
      body: briefAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('加载失败: $e')),
        data: (brief) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期标题
              Text(
                brief.date,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // 统计卡片
              Row(
                children: [
                  _StatCard(
                    icon: Icons.edit_note,
                    value: '${brief.recordCount}',
                    label: '记录数',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(
                    icon: Icons.timer,
                    value: '${brief.totalMinutes ~/ 60}h',
                    label: '总时长',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AI 摘要
              if (brief.summary != null) ...[
                _SectionTitle(title: '📝 AI 摘要'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(brief.summary!),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 高亮
              if (brief.highlights.isNotEmpty) ...[
                _SectionTitle(title: '⭐ 今日亮点'),
                ...brief.highlights.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(h)),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // 建议
              if (brief.suggestions.isNotEmpty) ...[
                _SectionTitle(title: '💡 智能建议'),
                ...brief.suggestions.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.orange),
                    title: Text(s),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}