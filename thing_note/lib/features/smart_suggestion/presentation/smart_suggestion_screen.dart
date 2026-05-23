import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_suggestion/data/smart_suggestion_repository.dart';

final _defaultSuggestions = [
  SmartSuggestion(
    suggestionType: 'habit',
    title: '💧 喝水的最佳时机',
    description: '现在是上午 10 点，距离你上次喝水已经 2 小时了',
    confidenceScore: 0.85,
    createdAt: DateTime.now(),
  ),
  SmartSuggestion(
    suggestionType: 'exercise',
    title: '🏃 今天天气很好，适合户外运动',
    description: '今天的空气质量指数为优，适合跑步或骑行',
    confidenceScore: 0.78,
    createdAt: DateTime.now(),
  ),
  SmartSuggestion(
    suggestionType: 'mood',
    title: '😌 建议进行冥想',
    description: '你最近压力较大，连续工作超过 4 小时了',
    confidenceScore: 0.72,
    createdAt: DateTime.now(),
  ),
  SmartSuggestion(
    suggestionType: 'social',
    title: '👋 记得联系朋友',
    description: '你上周和朋友的互动次数低于平均水平',
    confidenceScore: 0.65,
    createdAt: DateTime.now(),
  ),
];

class SmartSuggestionScreen extends ConsumerWidget {
  const SmartSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(smartSuggestionsProvider);
    final todaySuggestions = ref.watch(todaySuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能建议'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshSuggestions(context, ref),
          ),
        ],
      ),
      body: suggestionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (suggestions) => _buildContent(context, ref, suggestions, todaySuggestions),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<SmartSuggestion> all, AsyncValue<List<SmartSuggestion>> todayAsync) {
    final today = todayAsync.value ?? _defaultSuggestions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodaySuggestions(context, ref, today),
          const SizedBox(height: 24),
          _buildAllSuggestions(context, ref, all),
          const SizedBox(height: 24),
          _buildStats(context, ref),
        ],
      ),
    );
  }

  Widget _buildTodaySuggestions(BuildContext context, WidgetRef ref, List<SmartSuggestion> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('🌟', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('今日建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (suggestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  Text('✨', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('今天已处理所有建议'),
                ],
              ),
            ),
          )
        else
          ...suggestions.map((s) => _SuggestionCard(
            suggestion: s,
            onAccept: () => ref.read(smartSuggestionsProvider.notifier).acceptSuggestion(s.id!),
            onDismiss: () {},
          )),
      ],
    );
  }

  Widget _buildAllSuggestions(BuildContext context, WidgetRef ref, List<SmartSuggestion> suggestions) {
    final accepted = suggestions.where((s) => s.isAccepted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('已接受建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (accepted.isEmpty)
          const Text('暂无已接受的建议', style: TextStyle(color: Colors.grey))
        else
          ...accepted.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(s.title),
              subtitle: Text('接受于 ${s.acceptedAt}'),
            ),
          )),
      ],
    );
  }

  Widget _buildStats(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('建议统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: '今日建议', value: '${_defaultSuggestions.length}', icon: Icons.today),
              const _StatItem(label: '已接受', value: '0', icon: Icons.check_circle),
              const _StatItem(label: '采纳率', value: '0%', icon: Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  void _refreshSuggestions(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成新建议...')),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final SmartSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _SuggestionCard({
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

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
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(suggestion.suggestionType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeLabel(suggestion.suggestionType),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTypeColor(suggestion.suggestionType),
                    ),
                  ),
                ),
              ],
            ),
            if (suggestion.description != null) ...[
              const SizedBox(height: 8),
              Text(suggestion.description!, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(suggestion.confidenceScore * 100).toInt()}% 置信度',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('忽略'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('接受'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'habit': return Colors.blue;
      case 'exercise': return Colors.green;
      case 'mood': return Colors.purple;
      case 'social': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'habit': return '习惯';
      case 'exercise': return '运动';
      case 'mood': return '情绪';
      case 'social': return '社交';
      default: return '其他';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}