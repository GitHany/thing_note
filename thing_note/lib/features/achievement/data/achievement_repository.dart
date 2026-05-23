import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/achievement.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref);
});

class AchievementRepository {
  final Ref _ref;

  AchievementRepository(this._ref);

  Future<dynamic> get _db async {
    return await _ref.read(databaseProvider.future);
  }

  Future<int> insertAchievement(Achievement achievement) async {
    final db = await _db;
    return await db.insert('achievements', achievement.toMap());
  }

  Future<List<Achievement>> getAllAchievements() async {
    final db = await _db;
    final maps = await db.query('achievements', orderBy: 'is_unlocked DESC, current_value DESC');
    return maps.map((map) => Achievement.fromMap(map)).toList();
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final db = await _db;
    final maps = await db.query('achievements', where: 'is_unlocked = 1', orderBy: 'unlocked_at DESC');
    return maps.map((map) => Achievement.fromMap(map)).toList();
  }

  Future<int> updateAchievement(Achievement achievement) async {
    final db = await _db;
    return await db.update('achievements', achievement.toMap(), where: 'id = ?', whereArgs: [achievement.id]);
  }

  Future<Achievement?> getAchievementByType(String type) async {
    final db = await _db;
    final maps = await db.query('achievements', where: 'type = ?', whereArgs: [type], limit: 1);
    return maps.isNotEmpty ? Achievement.fromMap(maps.first) : null;
  }

  Future<void> initializeDefaultAchievements() async {
    final db = await _db;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM achievements');
    if ((count.first['count'] as int?) == 0) {
      for (final achievement in Achievement.defaultAchievements) {
        await db.insert('achievements', achievement.toMap());
      }
    }
  }

  Future<void> updateProgress(String type, int value) async {
    final db = await _db;
    await db.rawUpdate('UPDATE achievements SET current_value = ? WHERE type = ? AND current_value < ?', [value, type, value]);
    await db.rawUpdate('UPDATE achievements SET is_unlocked = 1, unlocked_at = ? WHERE type = ? AND current_value >= target_value AND is_unlocked = 0', [DateTime.now().toIso8601String(), type]);
  }
}