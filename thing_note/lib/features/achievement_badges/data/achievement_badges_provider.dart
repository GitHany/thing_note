import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/achievement_badges/domain/achievement_badge.dart';

final achievementBadgesProvider = StateNotifierProvider<AchievementBadgesNotifier, AsyncValue<List<AchievementBadge>>>((ref) {
  return AchievementBadgesNotifier(ref);
});

class AchievementBadgesNotifier extends StateNotifier<AsyncValue<List<AchievementBadge>>> {
  final Ref ref;

  AchievementBadgesNotifier(this.ref) : super(const AsyncValue.loading()) {
    initAndLoad();
  }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> initAndLoad() async {
    try {
      await _initDefaultBadges();
      await loadBadges();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _initDefaultBadges() async {
    final db = await _db;
    final existing = await db.query('achievement_badges');
    if (existing.isEmpty) {
      final templates = BadgeTemplates.getDefaultBadges();
      for (final badge in templates) {
        await db.insert('achievement_badges', badge.toMap()..remove('id'));
      }
    }
  }

  Future<void> loadBadges() async {
    try {
      state = const AsyncValue.loading();
      final db = await _db;
      final maps = await db.query('achievement_badges', orderBy: 'is_unlocked DESC, badge_type ASC');
      final badges = maps.map((m) => AchievementBadge.fromMap(m)).toList();
      state = AsyncValue.data(badges);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(String badgeId, int progress) async {
    final db = await _db;
    await db.update(
      'achievement_badges',
      {'current_progress': progress},
      where: 'badge_id = ?',
      whereArgs: [badgeId],
    );
    await loadBadges();
  }

  Future<bool> unlockBadge(String badgeId) async {
    final db = await _db;
    final results = await db.query(
      'achievement_badges',
      where: 'badge_id = ? AND is_unlocked = 0',
      whereArgs: [badgeId],
    );
    
    if (results.isNotEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.update(
        'achievement_badges',
        {'is_unlocked': 1, 'unlocked_at': now},
        where: 'badge_id = ?',
        whereArgs: [badgeId],
      );
      await loadBadges();
      return true;
    }
    return false;
  }

  Future<void> checkAndUpdateBadges({
    int? currentStreak,
    int? totalRecords,
    int? featuresUsed,
    int? customTags,
    int? earlyRecords,
  }) async {
    final db = await _db;
    
    if (currentStreak != null) {
      final streakBadges = await db.query(
        'achievement_badges',
        where: 'requirement_type = ? AND is_unlocked = 0',
        whereArgs: ['streak_days'],
      );
      
      for (final badge in streakBadges) {
        final required = badge['requirement_value'] as int;
        if (currentStreak >= required) {
          await unlockBadge(badge['badge_id'] as String);
        } else {
          await db.update(
            'achievement_badges',
            {'current_progress': currentStreak},
            where: 'badge_id = ?',
            whereArgs: [badge['badge_id']],
          );
        }
      }
    }

    if (totalRecords != null) {
      final recordBadges = await db.query(
        'achievement_badges',
        where: 'requirement_type = ? AND is_unlocked = 0',
        whereArgs: ['total_records'],
      );
      
      for (final badge in recordBadges) {
        final required = badge['requirement_value'] as int;
        if (totalRecords >= required) {
          await unlockBadge(badge['badge_id'] as String);
        } else {
          await db.update(
            'achievement_badges',
            {'current_progress': totalRecords},
            where: 'badge_id = ?',
            whereArgs: [badge['badge_id']],
          );
        }
      }
    }

    await loadBadges();
  }

  Future<List<AchievementBadge>> getUnlockedBadges() async {
    final badges = state.value ?? [];
    return badges.where((b) => b.isUnlocked == 1).toList();
  }

  Future<int> getTotalXp() async {
    final unlocked = await getUnlockedBadges();
    return unlocked.fold<int>(0, (sum, badge) => sum + badge.xpReward);
  }
}