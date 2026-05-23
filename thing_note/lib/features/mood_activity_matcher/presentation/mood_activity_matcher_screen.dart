import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_activity_matcher/data/mood_activity_matcher_provider.dart';
import 'package:thing_note/features/mood_activity_matcher/domain/mood_activity_matcher.dart';

class MoodActivityMatcherScreen extends ConsumerStatefulWidget {
  const MoodActivityMatcherScreen({super.key});

  @override
  ConsumerState<MoodActivityMatcherScreen> createState() => _MoodActivityMatcherScreenState();
}

class _MoodActivityMatcherScreenState extends ConsumerState<MoodActivityMatcherScreen> {
  @override
  Widget build(BuildContext context) {
    final mappingsAsync = ref.watch(moodActivityMappingsProvider);
    final recommendationsAsync = ref.watch(activityRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪活动匹配'),
      ),
      body: Column(
        children: [
          // Current Recommendation
          recommendationsAsync.when(
            data: (recommendations) => _buildRecommendationCard(recommendations),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(height: 100),
          ),
          const SizedBox(height: 16),

          // Activity Mappings
          Expanded(
            child: mappingsAsync.when(
              data: (mappings) => _buildMappingsList(mappings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMappingDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecommendationCard(List<ActivityRecommendation> recommendations) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final top = recommendations.first;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 推荐活动',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            top.activity,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '置信度: ${(top.confidence * 100).toInt()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingsList(List<MoodActivityMapping> mappings) {
    if (mappings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无活动记录'),
          ],
        ),
      );
    }

    final sorted = List.from(mappings)
      ..sort((a, b) => b.avgMood.compareTo(a.avgMood));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final mapping = sorted[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMoodColor(mapping.avgMood),
              child: Text('${mapping.avgMood}'),
            ),
            title: Text(mapping.activity),
            subtitle: Text('样本: ${mapping.sampleCount}'),
            trailing: Text(
              '${(mapping.avgMood * 20).toInt()}%',
              style: TextStyle(color: _getMoodColor(mapping.avgMood)),
            ),
          ),
        );
      },
    );
  }

  Color _getMoodColor(int mood) {
    if (mood >= 4) return Colors.green;
    if (mood >= 3) return Colors.blue;
    if (mood >= 2) return Colors.orange;
    return Colors.red;
  }

  void _showAddMappingDialog(BuildContext context) {
    final activityController = TextEditingController();
    int mood = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加活动'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: activityController,
                decoration: const InputDecoration(
                  labelText: '活动名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('平均情绪'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => mood = i),
                      icon: Icon(
                        i <= mood ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied,
                        color: i <= mood ? Colors.green : Colors.grey,
                      ),
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
                if (activityController.text.isNotEmpty) {
                  ref.read(moodActivityServiceProvider).addMapping(
                    activityController.text,
                    mood,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}