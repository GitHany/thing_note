import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mini_habits/domain/mini_habit.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final miniHabitsRepositoryProvider = Provider<MiniHabitsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MiniHabitsRepository(dbAsync);
});

final miniHabitsProvider = StateNotifierProvider<MiniHabitsNotifier, AsyncValue<List<MiniHabit>>>((ref) {
  final repo = ref.watch(miniHabitsRepositoryProvider);
  return MiniHabitsNotifier(repo);
});

final activeMiniHabitsProvider = Provider<AsyncValue<List<MiniHabit>>>((ref) {
  final habits = ref.watch(miniHabitsProvider);
  return habits.whenData((list) => list.where((h) => h.isActive).toList());
});

class MiniHabitsRepository {
  final AsyncValue<Database> _dbAsync;

  MiniHabitsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertHabit(MiniHabit habit) async {
    final db = await _db;
    return db.insert('mini_habits', habit.toMap());
  }

  Future<int> updateHabit(MiniHabit habit) async {
    final db = await _db;
    return db.update(
      'mini_habits',
      habit.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await _db;
    return db.delete('mini_habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MiniHabit>> getAllHabits() async {
    final db = await _db;
    final maps = await db.query('mini_habits', orderBy: 'created_at DESC');
    return maps.map((m) => MiniHabit.fromMap(m)).toList();
  }

  Future<List<MiniHabit>> getActiveHabits() async {
    final db = await _db;
    final maps = await db.query(
      'mini_habits',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => MiniHabit.fromMap(m)).toList();
  }

  Future<int> completeHabit(int habitId) async {
    final db = await _db;
    final now = DateTime.now();
    // Check if already completed today
    final logs = await db.query(
      'mini_habit_logs',
      where: 'habit_id = ? AND date(completed_at) = date(?)',
      whereArgs: [habitId, now.toIso8601String()],
    );
    if (logs.isNotEmpty) return 0;

    // Log the completion
    await db.insert('mini_habit_logs', {
      'habit_id': habitId,
      'completed_at': now.toIso8601String(),
      'duration_actual': 0,
      'created_at': now.toIso8601String(),
    });

    // Update habit stats
    final habits = await db.query('mini_habits', where: 'id = ?', whereArgs: [habitId]);
    if (habits.isEmpty) return 0;

    final habit = MiniHabit.fromMap(habits.first);
    final newStreak = habit.streakDays + 1;
    final newBest = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    return db.update(
      'mini_habits',
      {
        'streak_days': newStreak,
        'best_streak': newBest,
        'total_completions': habit.totalCompletions + 1,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  Future<bool> isCompletedToday(int habitId) async {
    final db = await _db;
    final now = DateTime.now();
    final logs = await db.query(
      'mini_habit_logs',
      where: 'habit_id = ? AND date(completed_at) = date(?)',
      whereArgs: [habitId, now.toIso8601String()],
    );
    return logs.isNotEmpty;
  }

  Future<int> getCompletionsForDate(int habitId, String date) async {
    final db = await _db;
    final logs = await db.query(
      'mini_habit_logs',
      where: 'habit_id = ? AND date(completed_at) = ?',
      whereArgs: [habitId, date],
    );
    return logs.length;
  }
}

class MiniHabitsNotifier extends StateNotifier<AsyncValue<List<MiniHabit>>> {
  final MiniHabitsRepository _repository;

  MiniHabitsNotifier(this._repository) : super(const AsyncValue.loading()) {
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

  Future<void> addHabit(MiniHabit habit) async {
    try {
      await _repository.insertHabit(habit);
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

  Future<void> deleteHabit(int id) async {
    try {
      await _repository.deleteHabit(id);
      await loadHabits();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
