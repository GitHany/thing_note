import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_streak_fire/domain/habit_streak_fire.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final streakFireRepositoryProvider = Provider<StreakFireRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return StreakFireRepository(dbAsync);
});

final streakFireMapProvider = FutureProvider<Map<int, HabitStreakFire>>((ref) async {
  final repo = ref.watch(streakFireRepositoryProvider);
  return repo.getAllStreakFires();
});

class StreakFireRepository {
  final AsyncValue<Database> _dbAsync;

  StreakFireRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> upsertStreakFire(HabitStreakFire streakFire) async {
    final db = await _db;
    final existing = await db.query(
      'habit_streak_fire',
      where: 'habit_id = ?',
      whereArgs: [streakFire.habitId],
    );
    if (existing.isNotEmpty) {
      return db.update('habit_streak_fire', streakFire.toMap(), where: 'habit_id = ?', whereArgs: [streakFire.habitId]);
    }
    return db.insert('habit_streak_fire', streakFire.toMap());
  }

  Future<HabitStreakFire?> getStreakFireByHabit(int habitId) async {
    final db = await _db;
    final maps = await db.query('habit_streak_fire', where: 'habit_id = ?', whereArgs: [habitId]);
    if (maps.isEmpty) return null;
    return HabitStreakFire.fromMap(maps.first);
  }

  Future<Map<int, HabitStreakFire>> getAllStreakFires() async {
    final db = await _db;
    final maps = await db.query('habit_streak_fire');
    return {for (final m in maps) m['habit_id'] as int: HabitStreakFire.fromMap(m)};
  }

  Future<int> updateStreak(int habitId, int newStreak, bool isCompleted) async {
    final db = await _db;
    final existing = await getStreakFireByHabit(habitId);
    final fireLevel = HabitStreakFire.calculateFireLevel(newStreak);
    final isOnFire = fireLevel >= 2;
    final now = DateTime.now();

    if (existing != null) {
      final bestStreak = newStreak > existing.bestStreak ? newStreak : existing.bestStreak;
      final totalFires = isOnFire && !existing.isOnFire ? existing.totalFires + 1 : existing.totalFires;
      return db.update(
        'habit_streak_fire',
        {
          'current_streak': newStreak,
          'best_streak': bestStreak,
          'fire_level': fireLevel,
          'is_on_fire': isOnFire ? 1 : 0,
          'total_fires': totalFires,
          'streak_start_date': existing.streakStartDate?.toIso8601String() ?? now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'habit_id = ?',
        whereArgs: [habitId],
      );
    } else {
      return db.insert('habit_streak_fire', {
        'habit_id': habitId,
        'current_streak': newStreak,
        'best_streak': newStreak,
        'streak_start_date': now.toIso8601String(),
        'fire_level': fireLevel,
        'total_fires': isOnFire ? 1 : 0,
        'flame_color': '#FF6B35',
        'is_on_fire': isOnFire ? 1 : 0,
        'updated_at': now.toIso8601String(),
      });
    }
  }

  Future<int> resetStreak(int habitId) async {
    final db = await _db;
    return db.update(
      'habit_streak_fire',
      {
        'current_streak': 0,
        'fire_level': 0,
        'is_on_fire': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
  }

  Future<List<HabitStreakFire>> getOnFireHabits() async {
    final db = await _db;
    final maps = await db.query(
      'habit_streak_fire',
      where: 'is_on_fire = 1',
      orderBy: 'current_streak DESC',
    );
    return maps.map((m) => HabitStreakFire.fromMap(m)).toList();
  }
}
