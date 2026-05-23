import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_suggestions/data/smart_suggestions_repository.dart';
import 'package:thing_note/features/smart_suggestions/domain/suggestion_models.dart';

class SmartSuggestionsScreen extends ConsumerStatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  ConsumerState<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends ConsumerState<SmartSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能建议'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '建议'),
            Tab(text: '情绪矩阵'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuggestionsTab(),
          _buildMoodMatrixTab(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    final suggestionsAsync = ref.watch(smartSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (suggestions) {
        final pending = suggestions.where((s) => !s.isAccepted).toList();
        final accepted = suggestions.where((s) => s.isAccepted).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              const Text('待处理建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...pending.map((s) => _SuggestionCard(
                suggestion: s,
                onAccept: () => ref.read(smartSuggestionsProvider.notifier).acceptSuggestion(s.id!),
                onDismiss: () => ref.read(smartSuggestionsProvider.notifier).dismissSuggestion(s.id!),
              )),
            ],
            if (accepted.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('已采纳建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ...accepted.map((s) => _AcceptedSuggestionCard(suggestion: s)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMoodMatrixTab() {
    final moodMatrixAsync = ref.watch(moodMatrixProvider);

    return moodMatrixAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (data) {
        if (data.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_on, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无情绪数据', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('记录你的活动和情绪，建立你的情绪矩阵', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '活动与精力/情绪关系',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '基于你的历史记录，分析哪些活动能提升你的精力和情绪',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildMoodMatrixGrid(data),
              const SizedBox(height: 24),
              const Text(
                '详细数据',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...data.map((item) => _MoodMatrixItemCard(item: item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodMatrixGrid(List<MoodMatrixData> data) {
    // Build a simple grid showing energy level vs mood impact
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 80),
                ...['低精力', '中精力', '高精力'].map((label) => Expanded(
                  child: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
                )),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(5, (energyLevel) {
              final levelData = data.where((d) => d.energyLevel == energyLevel).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('精力 $energyLevel', style: const TextStyle(fontSize: 12)),
                    ),
                    ...[1, 2, 3].map((moodLevel) {
                      final item = levelData.firstOrNull;
                      return Expanded(
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _getMoodColor(item?.moodImpactScore ?? 0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              item != null ? item.moodImpactScore.toStringAsFixed(1) : '-',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColorLegend(color: Colors.red.shade300, label: '负面'),
                _ColorLegend(color: Colors.grey.shade300, label: '中性'),
                _ColorLegend(color: Colors.green.shade300, label: '正面'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(double score) {
    if (score > 0.5) return Colors.green.shade300;
    if (score < -0.5) return Colors.red.shade300;
    return Colors.grey.shade300;
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
                Icon(_getTypeIcon(suggestion.suggestionType), color: _getTypeColor(suggestion.suggestionType)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _ConfidenceBadge(score: suggestion.confidenceScore),
              ],
            ),
            if (suggestion.description != null) ...[
              const SizedBox(height: 8),
              Text(suggestion.description!, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('忽略'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('采纳'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'habit':
        return Icons.repeat;
      case 'goal':
        return Icons.flag;
      case 'reminder':
        return Icons.alarm;
      case 'record':
        return Icons.note;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'habit':
        return Colors.blue;
      case 'goal':
        return Colors.orange;
      case 'reminder':
        return Colors.purple;
      case 'record':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _AcceptedSuggestionCard extends StatelessWidget {
  final SmartSuggestion suggestion;

  const _AcceptedSuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade100,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(suggestion.title),
        subtitle: suggestion.acceptedAt != null
            ? Text('采纳于 ${suggestion.acceptedAt!.month}/${suggestion.acceptedAt!.day}', style: const TextStyle(fontSize: 12))
            : null,
      ),
    );
  }
}

class _MoodMatrixItemCard extends StatelessWidget {
  final MoodMatrixData item;

  const _MoodMatrixItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.activityName),
        subtitle: Text('样本数: ${item.sampleCount}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getMoodColor(item.moodImpactScore).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${item.moodImpactScore >= 0 ? '+' : ''}${item.moodImpactScore.toStringAsFixed(2)}',
            style: TextStyle(
              color: _getMoodColor(item.moodImpactScore),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(double score) {
    if (score > 0.5) return Colors.green;
    if (score < -0.5) return Colors.red;
    return Colors.grey;
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double score;

  const _ConfidenceBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(score * 100).toStringAsFixed(0)}%',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ColorLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}