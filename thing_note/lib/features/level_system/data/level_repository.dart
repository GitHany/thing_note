import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/level_system/domain/user_level.dart';

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return LevelRepository(dbAsync);
});

class LevelRepository {
  final AsyncValue<Database> _dbAsync;

  LevelRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> initializeDefaultLevels() async {
    final db = await _db;
    final existing = await db.query('user_levels', limit: 1);
    if (existing.isEmpty) {
      final batch = db.batch();
      for (final level in UserLevel.defaultLevels) {
        batch.insert('user_levels', level.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    }
  }

  Future<UserProfile> getUserProfile() async {
    final db = await _db;

    await initializeDefaultLevels();

    final xpResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM xp_transactions'
    );
    final totalXp = (xpResult.first['total'] as num?)?.toInt() ?? 0;

    final levels = await db.query('user_levels', orderBy: 'level DESC');
    int currentLevel = 1;
    int xpInCurrentLevel = totalXp;
    int xpToNextLevel = 100;

    for (final levelMap in levels) {
      final level = UserLevel.fromMap(levelMap);
      if (totalXp >= level.xpRequired) {
        currentLevel = level.level;
        xpInCurrentLevel = totalXp - level.xpRequired;

        final nextLevelResult = await db.query(
          'user_levels',
          where: 'level > ?',
          whereArgs: [level.level],
          orderBy: 'level ASC',
          limit: 1,
        );

        if (nextLevelResult.isNotEmpty) {
          final nextLevel = UserLevel.fromMap(nextLevelResult.first);
          xpToNextLevel = nextLevel.xpRequired - level.xpRequired;
        } else {
          xpToNextLevel = 0;
        }
        break;
      }
    }

    final currentLevelInfo = levels.firstWhere(
      (l) => (l['level'] as int) == currentLevel,
      orElse: () => levels.first,
    );

    final currentLevelObj = UserLevel.fromMap(currentLevelInfo);
    UserLevel? nextLevelObj;

    if (currentLevel < 20) {
      final nextLevelResult = await db.query(
        'user_levels',
        where: 'level = ?',
        whereArgs: [currentLevel + 1],
      );
      if (nextLevelResult.isNotEmpty) {
        nextLevelObj = UserLevel.fromMap(nextLevelResult.first);
      }
    }

    return UserProfile(
      totalXp: totalXp,
      currentLevel: currentLevel,
      xpInCurrentLevel: xpInCurrentLevel,
      xpToNextLevel: xpToNextLevel,
      currentLevelInfo: currentLevelObj,
      nextLevelInfo: nextLevelObj,
    );
  }

  Future<void> addXpTransaction(XpTransaction transaction) async {
    final db = await _db;
    await db.insert('xp_transactions', transaction.toMap()..remove('id'));
  }

  Future<void> awardXp(int amount, String source, {int? sourceId, String? description}) async {
    final transaction = XpTransaction(
      amount: amount,
      source: source,
      sourceId: sourceId,
      description: description,
      createdAt: DateTime.now().toIso8601String(),
    );
    await addXpTransaction(transaction);
  }

  Future<List<XpTransaction>> getRecentTransactions({int limit = 10}) async {
    final db = await _db;
    final result = await db.query(
      'xp_transactions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((map) => XpTransaction.fromMap(map)).toList();
  }

  Future<void> initializeDailyQuests() async {
    final db = await _db;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.query(
      'daily_quests',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (existing.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final quests = [
        DailyQuest(
          questType: 'record',
          title: '记录今天',
          description: '创建至少 1 条记录',
          xpReward: 10,
          date: dateStr,
          createdAt: now,
        ),
        DailyQuest(
          questType: 'habit',
          title: '养成习惯',
          description: '完成至少 1 个习惯打卡',
          xpReward: 15,
          date: dateStr,
          createdAt: now,
        ),
        DailyQuest(
          questType: 'mood',
          title: '记录心情',
          description: '记录今天的情绪',
          xpReward: 5,
          date: dateStr,
          createdAt: now,
        ),
        DailyQuest(
          questType: 'search',
          title: '回顾过去',
          description: '搜索查看历史记录',
          xpReward: 5,
          date: dateStr,
          createdAt: now,
        ),
      ];

      final batch = db.batch();
      for (final quest in quests) {
        batch.insert('daily_quests', quest.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<DailyQuest>> getDailyQuests() async {
    final db = await _db;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await initializeDailyQuests();

    final result = await db.query(
      'daily_quests',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );

    return result.map((map) => DailyQuest.fromMap(map)).toList();
  }

  Future<void> updateQuestProgress(int questId, int progress) async {
    final db = await _db;
    final quest = await db.query(
      'daily_quests',
      where: 'id = ?',
      whereArgs: [questId],
    );

    if (quest.isNotEmpty) {
      final currentQuest = DailyQuest.fromMap(quest.first);
      final isCompleted = progress >= currentQuest.targetCount;

      await db.update(
        'daily_quests',
        {
          'current_count': progress,
          'is_completed': isCompleted ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [questId],
      );

      if (isCompleted && currentQuest.currentCount < currentQuest.targetCount) {
        await awardXp(
          currentQuest.xpReward,
          'daily_quest',
          sourceId: questId,
          description: '完成每日任务: ${currentQuest.title}',
        );
      }
    }
  }

  Future<int> getCompletedQuestsCount() async {
    final db = await _db;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_quests WHERE date = ? AND is_completed = 1',
      [dateStr],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalXpToday() async {
    final db = await _db;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM xp_transactions WHERE created_at >= ?',
      [startOfDay],
    );

    return (result.first['total'] as int?) ?? 0;
  }
}
