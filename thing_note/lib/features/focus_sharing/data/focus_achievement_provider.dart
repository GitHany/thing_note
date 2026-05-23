import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/focus_sharing/domain/focus_achievement_model.dart';

final focusAchievementsProvider = FutureProvider<List<FocusAchievement>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('focus_achievements', orderBy: 'is_unlocked DESC, share_count DESC');
  return results.map((m) => FocusAchievement.fromMap(m)).toList();
});

class FocusAchievementNotifier extends StateNotifier<AsyncValue<List<FocusAchievement>>> {
  final Ref ref;
  
  FocusAchievementNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadAchievements();
  }
  
  Future<void> _loadAchievements() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('focus_achievements', orderBy: 'share_count DESC');
      state = AsyncValue.data(results.map((m) => FocusAchievement.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> unlockAchievement(int achievementId) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'focus_achievements',
      {
        'is_unlocked': 1,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [achievementId],
    );
    await _loadAchievements();
  }
  
  Future<void> shareAchievement(int achievementId) async {
    final db = await ref.read(databaseProvider.future);
    await db.rawUpdate(
      'UPDATE focus_achievements SET share_count = share_count + 1 WHERE id = ?',
      [achievementId],
    );
    await _loadAchievements();
  }
}

final focusAchievementNotifierProvider =
    StateNotifierProvider<FocusAchievementNotifier, AsyncValue<List<FocusAchievement>>>((ref) {
  return FocusAchievementNotifier(ref);
});