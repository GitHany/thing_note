import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/achievement_repository.dart';
import '../domain/achievement.dart';

final achievementProvider = StateNotifierProvider<AchievementNotifier, AsyncValue<List<Achievement>>>((ref) {
  return AchievementNotifier(ref.watch(achievementRepositoryProvider));
});

class AchievementNotifier extends StateNotifier<AsyncValue<List<Achievement>>> {
  final AchievementRepository _repository;

  AchievementNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _repository.initializeDefaultAchievements();
    await loadAchievements();
  }

  Future<void> loadAchievements() async {
    state = const AsyncValue.loading();
    try {
      final achievements = await _repository.getAllAchievements();
      state = AsyncValue.data(achievements);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(String type, int value) async {
    await _repository.updateProgress(type, value);
    await loadAchievements();
  }
}

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就系统'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: achievementsAsync.when(
        data: (achievements) => _buildAchievementList(context, ref, achievements),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
    );
  }

  Widget _buildAchievementList(BuildContext context, WidgetRef ref, List<Achievement> achievements) {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, unlocked.length.toString(), '已解锁', Colors.amber),
                  _buildStatItem(context, locked.length.toString(), '未解锁', Colors.grey),
                  _buildStatItem(context, '${((unlocked.length / achievements.length) * 100).toStringAsFixed(0)}%', '完成率', Colors.green),
                ],
              ),
            ),
          ),
        ),
        if (unlocked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('🏆 已解锁成就 (${unlocked.length})', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildAchievementItem(context, unlocked[index]),
            childCount: unlocked.length,
          )),
        ],
        if (locked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('🔒 进行中 (${locked.length})', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildAchievementItem(context, locked[index]),
            childCount: locked.length,
          )),
        ],
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAchievementItem(BuildContext context, Achievement achievement) {
    final progress = achievement.progress;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isUnlocked ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(achievement.title, style: Theme.of(context).textTheme.titleMedium)),
                      if (achievement.isUnlocked) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  if (achievement.description != null) Text(achievement.description!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  if (!achievement.isUnlocked) ...[
                    LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Text('${achievement.currentValue}/${achievement.targetValue}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}