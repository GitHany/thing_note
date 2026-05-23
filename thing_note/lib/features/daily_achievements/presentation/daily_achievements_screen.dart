import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_achievements/data/daily_achievement_provider.dart';
import 'package:thing_note/features/daily_achievements/domain/daily_challenge_model.dart';

class DailyAchievementsScreen extends ConsumerWidget {
  const DailyAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(dailyAchievementNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日成就'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => _showAchievementCollection(context),
            tooltip: '成就收藏',
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily Progress
          _buildDailyProgress(context, challengesAsync),
          
          // Challenges List
          Expanded(
            child: challengesAsync.when(
              data: (challenges) => _buildChallengesList(context, ref, challenges),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _refreshChallenges(context, ref),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDailyProgress(BuildContext context, AsyncValue<List<DailyChallenge>> challengesAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: challengesAsync.when(
        data: (challenges) {
          final completed = challenges.where((c) => c.isCompleted).length;
          final total = challenges.length;
          final progress = total > 0 ? completed / total : 0.0;
          final totalXp = challenges.fold(0, (sum, c) => sum + c.xpReward);
          
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今日成就',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed / $total 已完成',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '+$totalXp XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('加载失败'),
      ),
    );
  }

  Widget _buildChallengesList(BuildContext context, WidgetRef ref, List<DailyChallenge> challenges) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '今日暂无挑战',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击刷新获取今日挑战',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(context, ref, challenge);
      },
    );
  }

  Widget _buildChallengeCard(BuildContext context, WidgetRef ref, DailyChallenge challenge) {
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
                    color: _getChallengeColor(challenge.challengeType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getChallengeIcon(challenge.challengeType),
                    color: _getChallengeColor(challenge.challengeType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: challenge.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (challenge.description != null)
                        Text(
                          challenge.description!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '+${challenge.xpReward}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!challenge.isCompleted && challenge.targetValue != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: challenge.progress,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${challenge.currentValue}/${challenge.targetValue}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!challenge.isCompleted)
                  TextButton.icon(
                    onPressed: () => ref.read(dailyAchievementNotifierProvider.notifier).completeChallenge(challenge.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('完成'),
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '已完成',
                        style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChallengeColor(String type) {
    switch (type) {
      case 'record':
        return Colors.blue;
      case 'habit':
        return Colors.green;
      case 'explore':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getChallengeIcon(String type) {
    switch (type) {
      case 'record':
        return Icons.edit_note;
      case 'habit':
        return Icons.repeat;
      case 'explore':
        return Icons.explore;
      default:
        return Icons.star;
    }
  }

  void _showAchievementCollection(BuildContext context) {
    final achievements = [
      Achievement(name: '首次记录', emoji: '📝', unlocked: true, rarity: 'common'),
      Achievement(name: '连续7天', emoji: '🔥', unlocked: true, rarity: 'rare'),
      Achievement(name: '100条记录', emoji: '💯', unlocked: false, rarity: 'epic'),
      Achievement(name: '完美一天', emoji: '⭐', unlocked: false, rarity: 'legendary'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '成就收藏',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: achievement.unlocked
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        achievement.emoji,
                        style: TextStyle(
                          fontSize: 32,
                          color: achievement.unlocked ? null : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshChallenges(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在刷新挑战...')),
    );
  }
}