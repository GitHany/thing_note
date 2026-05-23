import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_sharing/data/focus_achievement_provider.dart';
import 'package:thing_note/features/focus_sharing/domain/focus_achievement_model.dart';

class FocusSharingScreen extends ConsumerWidget {
  const FocusSharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(focusAchievementNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注成就分享'),
      ),
      body: achievementsAsync.when(
        data: (achievements) => _buildAchievementsList(context, ref, achievements),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCardDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('生成成就卡'),
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context, WidgetRef ref, List<FocusAchievement> achievements) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无成就',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '完成专注训练获取成就',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(context, ref, achievement);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, WidgetRef ref, FocusAchievement achievement) {
    return GestureDetector(
      onTap: () => _showShareOptions(context, ref, achievement),
      child: Container(
        decoration: BoxDecoration(
          gradient: achievement.isUnlocked
              ? LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: achievement.isUnlocked ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    achievement.badgeIcon ?? '🎯',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked ? Colors.white : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (achievement.description != null)
                    Text(
                      achievement.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: achievement.isUnlocked ? Colors.white70 : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '分享 ${achievement.shareCount} 次',
                    style: TextStyle(
                      fontSize: 11,
                      color: achievement.isUnlocked ? Colors.white54 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (!achievement.isUnlocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context, WidgetRef ref, FocusAchievement achievement) {
    if (!achievement.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先解锁这个成就')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享到社交媒体'),
              onTap: () {
                Navigator.pop(context);
                ref.read(focusAchievementNotifierProvider.notifier).shareAchievement(achievement.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分享成功!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制成就信息'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成成就卡'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text(
                    '专注新星',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '完成首次30分钟专注',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择成就样式并分享'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('成就卡已保存')),
              );
            },
            child: const Text('保存并分享'),
          ),
        ],
      ),
    );
  }
}