import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/habit_watermark_models.dart';

/// 习惯水印服务提供者
final habitWatermarkServiceProvider = Provider<HabitWatermarkService>((ref) {
  return HabitWatermarkService(ref.read(databaseProvider.future));
});

/// 习惯水印服务
class HabitWatermarkService {
  final Future<Database> _db;

  HabitWatermarkService(this._db);

  /// 获取习惯打卡状态列表
  Future<List<HabitCheckStatus>> getHabitCheckStatuses({List<int>? habitIds}) async {
    final db = await _db;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (habitIds != null && habitIds.isNotEmpty) {
      whereClause = 'WHERE id IN (${habitIds.map((_) => '?').join(',')})';
      whereArgs = habitIds;
    }

    final habits = await db.rawQuery(
      'SELECT * FROM habits $whereClause ORDER BY sort_order',
      whereArgs,
    );

    if (habits.isEmpty) return [];

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final statuses = <HabitCheckStatus>[];

    for (final habit in habits) {
      final habitId = habit['id'] as int;
      final habitName = habit['name'] as String;
      final icon = habit['icon'] as String?;

      // 获取今天的打卡状态
      final todayCheck = await db.query(
        'habit_check_ins',
        where: 'habit_id = ? AND check_date = ?',
        whereArgs: [habitId, todayStr],
        limit: 1,
      );

      // 计算连续天数
      int currentStreak = 0;
      int bestStreak = 0;
      DateTime? lastCheckTime;

      if (todayCheck.isNotEmpty) {
        currentStreak = (todayCheck.first['streak'] as int?) ?? 0;
        lastCheckTime = DateTime.parse(todayCheck.first['check_time'] as String);
      }

      // 获取最佳连续记录
      final bestStreakVal = habit['best_streak'] as int?;
      bestStreak = bestStreakVal ?? 0;

      statuses.add(HabitCheckStatus(
        habitId: habitId,
        habitName: habitName,
        isCheckedToday: todayCheck.isNotEmpty,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        lastCheckTime: lastCheckTime,
        icon: icon,
      ));
    }

    return statuses;
  }

  /// 获取记录关联的习惯状态
  Future<List<HabitCheckStatus>> getStatusesForRecord(int recordId) async {
    final db = await _db;

    // 获取记录关联的习惯 ID
    final links = await db.query(
      'record_habit_links',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );

    if (links.isEmpty) return [];

    final habitIds = links.map((l) => l['habit_id'] as int).toList();
    return getHabitCheckStatuses(habitIds: habitIds);
  }

  /// 获取配置
  Future<HabitWatermarkConfig> getConfig() async {
    final db = await _db;

    final rows = await db.query(
      'habit_watermark_config',
      limit: 1,
    );

    if (rows.isEmpty) {
      return HabitWatermarkConfig();
    }

    return HabitWatermarkConfig.fromMap(rows.first);
  }

  /// 保存配置
  Future<void> saveConfig(HabitWatermarkConfig config) async {
    final db = await _db;

    await db.delete('habit_watermark_config');

    await db.insert('habit_watermark_config', {
      'enabled': config.enabled ? 1 : 0,
      'position': config.position.name,
      'style': config.style.name,
      'habit_ids': config.habitIds.join(','),
      'show_streak': config.showStreak ? 1 : 0,
      'show_icon': config.showIcon ? 1 : 0,
      'opacity': config.opacity,
    });
  }

  /// 打卡
  Future<void> checkIn(int habitId) async {
    final db = await _db;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 检查是否已经打卡
    final existing = await db.query(
      'habit_check_ins',
      where: 'habit_id = ? AND check_date = ?',
      whereArgs: [habitId, today],
    );

    if (existing.isNotEmpty) {
      // 已打卡，删除打卡记录
      await db.delete(
        'habit_check_ins',
        where: 'habit_id = ? AND check_date = ?',
        whereArgs: [habitId, today],
      );
    } else {
      // 计算连续天数
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      int streak = 1;
      final yesterdayCheck = await db.query(
        'habit_check_ins',
        where: 'habit_id = ? AND check_date = ?',
        whereArgs: [habitId, yesterdayStr],
      );

      if (yesterdayCheck.isNotEmpty) {
        streak = ((yesterdayCheck.first['streak'] as int?) ?? 0) + 1;
      }

      await db.insert('habit_check_ins', {
        'habit_id': habitId,
        'check_date': today,
        'check_time': now.toIso8601String(),
        'streak': streak,
      });

      // 更新习惯的最佳连续
      final habit = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      if (habit.isNotEmpty) {
        final bestStreak = (habit.first['best_streak'] as int?) ?? 0;
        if (streak > bestStreak) {
          await db.update(
            'habits',
            {'best_streak': streak},
            where: 'id = ?',
            whereArgs: [habitId],
          );
        }
      }
    }
  }

  /// 关联记录和习惯
  Future<void> linkRecordToHabit(int recordId, int habitId) async {
    final db = await _db;

    await db.insert('record_habit_links', {
      'record_id': recordId,
      'habit_id': habitId,
      'linked_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// 取消关联
  Future<void> unlinkRecordFromHabit(int recordId, int habitId) async {
    final db = await _db;

    await db.delete(
      'record_habit_links',
      where: 'record_id = ? AND habit_id = ?',
      whereArgs: [recordId, habitId],
    );
  }
}