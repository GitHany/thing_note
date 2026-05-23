import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/achievement_badges/data/achievement_badges_provider.dart';
import 'package:thing_note/features/achievement_badges/domain/achievement_badge.dart';

class AchievementBadgesScreen extends ConsumerWidget {
  const AchievementBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(achievementBadgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就徽章'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => _showXpDialog(context, ref),
          ),
        ],
      ),
      body: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (badges) {
          final unlockedBadges = badges.where((b) => b.isUnlocked == 1).toList();
          final lockedBadges = badges.where((b) => b.isUnlocked == 0).toList();
          final totalXp = unlockedBadges.fold(0, (sum, b) => sum + b.xpReward);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(unlockedBadges.length, badges.length, totalXp),
              ),
              if (unlockedBadges.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('已解锁', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBadgeCard(context, unlockedBadges[index], true),
                      childCount: unlockedBadges.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('进行中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildBadgeCard(context, lockedBadges[index], false),
                    childCount: lockedBadges.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total, int xp) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('已解锁', '$unlocked/$total', Icons.emoji_events),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStat('总经验', '$xp XP', Icons.star),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBadgeCard(BuildContext context, AchievementBadge badge, bool isUnlocked) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isUnlocked
              ? [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.iconDisplay,
              style: TextStyle(fontSize: 32, color: isUnlocked ? null : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              badge.badgeName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isUnlocked && badge.requirementValue != null) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: badge.progressPercent,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${badge.currentProgress}/${badge.requirementValue}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, AchievementBadge badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.iconDisplay,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              badge.badgeName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.typeLabel,
                style: const TextStyle(color: Colors.purple),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.description ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (badge.isUnlocked == 1)
              const Text('🎉 已解锁!', style: TextStyle(color: Colors.green, fontSize: 18))
            else
              Text('+${badge.xpReward} XP', style: const TextStyle(color: Colors.amber, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showXpDialog(BuildContext context, WidgetRef ref) async {
    final totalXp = await ref.read(achievementBadgesProvider.notifier).getTotalXp();
    
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('总经验值'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$totalXp',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const Text('XP'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}