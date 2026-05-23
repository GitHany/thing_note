import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit/domain/habit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitRepository(dbAsync);
});

final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitsNotifier(repository);
});

final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsProvider);
  return habits.whenOrNull(data: (list) => list) ?? [];
});

class HabitRepository {
  final AsyncValue<Database> _dbAsync;

  HabitRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertHabit(Habit habit) async {
    final db = await _db;
    return db.insert('habits', habit.toMap());
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await _db;
    return db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await _db;
    return db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await _db;
    final maps = await db.query('habits', orderBy: 'created_at DESC');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<Habit?> getHabitById(int id) async {
    final db = await _db;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<void> completeHabit(int habitId) async {
    final db = await _db;
    final habit = await getHabitById(habitId);
    if (habit == null) return;

    final now = DateTime.now();
    int newStreak = habit.currentStreak;

    if (habit.lastCompletedAt != null) {
      final lastCompleted = habit.lastCompletedAt!;
      final daysDiff = now.difference(lastCompleted).inDays;

      if (daysDiff <= 1) {
        newStreak++;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newBestStreak = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    await db.update(
      'habits',
      {
        'last_completed_at': now.toIso8601String(),
        'current_streak': newStreak,
        'best_streak': newBestStreak,
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );

    await db.insert('habit_logs', {
      'habit_id': habitId,
      'completed_at': now.toIso8601String(),
      'note': null,
    });
  }

  Future<List<HabitLog>> getHabitLogs(int habitId, {int limit = 30}) async {
    final db = await _db;
    final maps = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return maps.map((m) => HabitLog.fromMap(m)).toList();
  }

  Future<Map<int, int>> getCompletionCounts(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'habit_logs',
      where: 'completed_at >= ? AND completed_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    final counts = <int, int>{};
    for (final map in maps) {
      final habitId = map['habit_id'] as int;
      counts[habitId] = (counts[habitId] ?? 0) + 1;
    }
    return counts;
  }
}

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final HabitRepository _repository;

  HabitsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final habits = await _repository.getAllHabits();
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _repository.insertHabit(habit);
      await loadHabits();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _repository.updateHabit(habit);
      await loadHabits();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteHabit(int id) async {
    try {
      await _repository.deleteHabit(id);
      await loadHabits();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeHabit(int habitId) async {
    try {
      await _repository.completeHabit(habitId);
      await loadHabits();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}