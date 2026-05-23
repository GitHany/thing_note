import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyDigestProvider = StateNotifierProvider<DailyDigestNotifier, Map<String, dynamic>>((ref) {
  return DailyDigestNotifier();
});

class DailyDigestNotifier extends StateNotifier<Map<String, dynamic>> {
  DailyDigestNotifier() : super({
    'date': '2026-05-22',
    'record_count': 5,
    'habits': [
      {'name': '喝水', 'completed': true},
      {'name': '运动', 'completed': false},
      {'name': '早睡', 'completed': true},
    ],
    'goals': [
      {'name': '读完一本书', 'progress': 60},
      {'name': '学习英语', 'progress': 40},
    ],
    'highlights': ['完成了一个重要的项目', '和朋友聚餐'],
    'suggestions': ['建议今天多喝水', '可以尝试新的运动方式'],
  });

  void generateDigest() {}
}

class DailyDigestScreen extends ConsumerWidget {
  const DailyDigestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(dailyDigestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日摘要'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDigest(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(digest),
            const SizedBox(height: 24),
            _buildRecordSummary(digest),
            const SizedBox(height: 24),
            _buildHabitsSummary(digest),
            const SizedBox(height: 24),
            _buildGoalsSummary(digest),
            const SizedBox(height: 24),
            _buildHighlights(digest),
            const SizedBox(height: 24),
            _buildSuggestions(digest),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(Map<String, dynamic> digest) {
    final date = digest['date'] as String;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日摘要',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordSummary(Map<String, dynamic> digest) {
    final count = digest['record_count'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue),
              SizedBox(width: 8),
              Text('记录概览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(label: '记录数', value: '$count', icon: Icons.note),
              const _SummaryItem(label: '习惯完成', value: '2/3', icon: Icons.check_circle),
              const _SummaryItem(label: '目标进度', value: '50%', icon: Icons.flag),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSummary(Map<String, dynamic> digest) {
    final habits = digest['habits'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.repeat, color: Colors.green),
              SizedBox(width: 8),
              Text('习惯完成情况', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...habits.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  h['completed'] == true ? Icons.check_circle : Icons.circle_outlined,
                  color: h['completed'] == true ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(h['name'] as String),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGoalsSummary(Map<String, dynamic> digest) {
    final goals = digest['goals'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag, color: Colors.orange),
              SizedBox(width: 8),
              Text('目标进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...goals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(g['name'] as String),
                    Text('${g['progress']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (g['progress'] as int) / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHighlights(Map<String, dynamic> digest) {
    final highlights = digest['highlights'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('今日亮点', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (highlights.isEmpty)
            const Text('暂无亮点')
          else
            ...highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(h)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildSuggestions(Map<String, dynamic> digest) {
    final suggestions = digest['suggestions'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('明日建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            const Text('暂无建议')
          else
            ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  void _shareDigest(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}