import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/celebration_tracker/data/celebration_tracker_repository.dart';
import 'package:thing_note/features/celebration_tracker/domain/celebration.dart';

class CelebrationTrackerScreen extends ConsumerWidget {
  const CelebrationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celebrationsAsync = ref.watch(celebrationsProvider);
    final statsAsync = ref.watch(celebrationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就庆祝'),
      ),
      body: Column(
        children: [
          _buildBadges(statsAsync),
          Expanded(
            child: celebrationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误: $e')),
              data: (celebrations) {
                if (celebrations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无成就', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('记录你的每一次进步', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('记录成就'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: celebrations.length,
                  itemBuilder: (context, index) {
                    final celebration = celebrations[index];
                    return _CelebrationCard(celebration: celebration);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBadges(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final totalCount = stats['total_count'] as int? ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.amber.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏆 成就徽章', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Celebration.badgeDefinitions.map((badge) {
                  final unlocked = totalCount >= (badge['requirement'] as int);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: unlocked ? Colors.amber.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: unlocked ? Border.all(color: Colors.amber, width: 2) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(badge['icon'] as String, style: TextStyle(fontSize: 16, color: unlocked ? null : Colors.grey)),
                        const SizedBox(width: 4),
                        Text(
                          badge['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: unlocked ? Colors.amber.shade800 : Colors.grey,
                          ),
                        ),
                        if (!unlocked) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${badge['requirement']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'daily_win';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录成就'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '成就标题'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                ),
                const SizedBox(height: 16),
                const Text('成就类型'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Celebration.celebrationTypes.map((type) {
                    return ChoiceChip(
                      selected: selectedType == type,
                      label: Text('${Celebration.typeEmojis[type]} ${Celebration.typeLabels[type]}'),
                      onSelected: (selected) {
                        if (selected) setState(() => selectedType = type);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final celebration = Celebration(
                    title: titleController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    celebrationType: selectedType,
                  );
                  ref.read(celebrationsProvider.notifier).addCelebration(celebration);
                  Navigator.pop(context);
                }
              },
              child: const Text('庆祝！'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationCard extends ConsumerWidget {
  final Celebration celebration;

  const _CelebrationCard({required this.celebration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Celebration.typeEmojis[celebration.celebrationType] ?? '🎉',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        celebration.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (celebration.description != null)
                        Text(
                          celebration.description!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  Celebration.typeLabels[celebration.celebrationType] ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${celebration.achievedAt.month}/${celebration.achievedAt.day}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    celebration.shared == 1 ? Icons.share : Icons.share_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(celebrationsProvider.notifier).shareCelebration(celebration.id!);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}