import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_streak/domain/habit_streak.dart';

final habitStreakRepositoryProvider = Provider<HabitStreakRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitStreakRepository(dbAsync);
});

class HabitStreakRepository {
  final AsyncValue<Database> _dbAsync;

  HabitStreakRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insert(HabitStreak streak) async {
    final db = await _db;
    return await db.insert('habit_streaks', streak.toMap());
  }

  Future<List<HabitStreak>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_streaks',
      orderBy: 'current_streak DESC',
    );
    return maps.map((map) => HabitStreak.fromMap(map)).toList();
  }

  Future<HabitStreak?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_streaks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return HabitStreak.fromMap(maps.first);
  }

  Future<int> update(HabitStreak streak) async {
    final db = await _db;
    return await db.update(
      'habit_streaks',
      streak.toMap(),
      where: 'id = ?',
      whereArgs: [streak.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'habit_streaks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<HabitStreak?> checkIn(int id) async {
    final streak = await getById(id);
    if (streak == null) return null;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    int newStreak = streak.currentStreak;
    if (streak.lastCheckIn == yesterday) {
      newStreak = streak.currentStreak + 1;
    } else if (streak.lastCheckIn != today) {
      newStreak = 1;
    }

    final newLongest = newStreak > streak.longestStreak ? newStreak : streak.longestStreak;

    final updated = streak.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCheckIn: today,
    );

    await update(updated);
    return updated;
  }

  Future<int> getTotalActiveStreaks() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habit_streaks WHERE current_streak > 0',
    );
    return result.first['count'] as int;
  }
}
