import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/level_system/data/level_repository.dart';
import 'package:thing_note/features/level_system/domain/user_level.dart';

final levelSystemProvider = FutureProvider<UserProfile>((ref) async {
  final repository = ref.watch(levelRepositoryProvider);
  return await repository.getUserProfile();
});

final dailyQuestsProvider = FutureProvider<List<DailyQuest>>((ref) async {
  final repository = ref.watch(levelRepositoryProvider);
  return await repository.getDailyQuests();
});

final recentTransactionsProvider = FutureProvider<List<XpTransaction>>((ref) async {
  final repository = ref.watch(levelRepositoryProvider);
  return await repository.getRecentTransactions();
});

class LevelSystemScreen extends ConsumerStatefulWidget {
  const LevelSystemScreen({super.key});

  @override
  ConsumerState<LevelSystemScreen> createState() => _LevelSystemScreenState();
}

class _LevelSystemScreenState extends ConsumerState<LevelSystemScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(levelSystemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成长等级'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        data: (profile) => _buildContent(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLevelCard(context, profile),
          const SizedBox(height: 24),
          _buildXpProgressCard(context, profile),
          const SizedBox(height: 24),
          _buildDailyQuestsCard(context),
          const SizedBox(height: 24),
          _buildRecentActivityCard(context),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, UserProfile profile) {
    final levelInfo = profile.currentLevelInfo;
    final badgeColor = UserLevel.getBadgeColor(profile.currentLevel);
    final badgeIcon = UserLevel.getBadgeIconData(levelInfo?.badgeIcon);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animation.value),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 8,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                badgeColor.withOpacity(0.2),
                badgeColor.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor.withOpacity(0.3),
                      border: Border.all(color: badgeColor, width: 3),
                    ),
                    child: Icon(
                      badgeIcon,
                      size: 50,
                      color: badgeColor,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lv.${profile.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                levelInfo?.title ?? '未知',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                levelInfo?.badgeIcon ?? '⭐',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                '总经验值: ${profile.totalXp} XP',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpProgressCard(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '升级进度',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${profile.xpInCurrentLevel}/${profile.xpToNextLevel} XP',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: profile.levelProgress,
                minHeight: 16,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  UserLevel.getBadgeColor(profile.currentLevel),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lv.${profile.currentLevel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  profile.nextLevelInfo != null
                      ? 'Lv.${profile.nextLevelInfo!.level}'
                      : '满级',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuestsCard(BuildContext context) {
    final questsAsync = ref.watch(dailyQuestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '每日任务',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Consumer(
              builder: (context, ref, _) {
                final repository = ref.watch(levelRepositoryProvider);
                return FutureBuilder<int>(
                  future: repository.getCompletedQuestsCount(),
                  builder: (context, snapshot) {
                    return Text(
                      '已完成 ${snapshot.data ?? 0}/4',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        questsAsync.when(
          data: (quests) => Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quests.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final quest = quests[index];
                return _buildQuestTile(context, quest);
              },
            ),
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('加载失败: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestTile(BuildContext context, DailyQuest quest) {
    final isCompleted = quest.isCompleted;
    final progress = quest.progress;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Icon(
          isCompleted ? Icons.check : Icons.pending,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(
        quest.title,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quest.description != null)
            Text(
              quest.description!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${quest.currentCount}/${quest.targetCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '+${quest.xpReward} XP',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近获得经验',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '暂无记录\n完成每日任务获取经验值',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              );
            }
            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length.clamp(0, 5),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.amber,
                      ),
                    ),
                    title: Text(tx.description ?? _getSourceLabel(tx.source)),
                    subtitle: Text(
                      _formatTime(tx.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '+${tx.amount}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('加载失败: $e')),
            ),
          ),
        ),
      ],
    );
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'daily_quest':
        return '完成每日任务';
      case 'record':
        return '创建记录';
      case 'habit':
        return '习惯打卡';
      case 'mood':
        return '记录心情';
      default:
        return source;
    }
  }

  String _formatTime(String isoTime) {
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${date.month}/${date.day}';
    } catch (_) {
      return isoTime;
    }
  }
}
