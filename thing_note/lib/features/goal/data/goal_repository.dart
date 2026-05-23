import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/goal/domain/goal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return GoalRepository(dbAsync);
});

final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<List<Goal>>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalsNotifier(repository);
});

final activeGoalsProvider = Provider<AsyncValue<List<Goal>>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.whenData((list) => list.where((g) => g.status == GoalStatus.active).toList());
});

class GoalRepository {
  final AsyncValue<Database> _dbAsync;

  GoalRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertGoal(Goal goal) async {
    final db = await _db;
    return db.insert('goals', goal.toMap());
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await _db;
    return db.update(
      'goals',
      goal.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await _db;
    return db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await _db;
    final maps = await db.query('goals', orderBy: 'created_at DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  Future<Goal?> getGoalById(int id) async {
    final db = await _db;
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

Future<List<Goal>> getGoalsByStatus(GoalStatus status) async {
    final db = await _db;
    final whereArgs = [status.name];
    final maps = await db.query('goals', where: 'status = ?', whereArgs: whereArgs);
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  Future<int> updateProgress(int goalId, int progress) async {
    final db = await _db;
    return db.update(
      'goals',
      {'current_progress': progress, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}

class GoalsNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final GoalRepository _repository;

  GoalsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getAllGoals();
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      await _repository.insertGoal(goal);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _repository.updateGoal(goal);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _repository.deleteGoal(id);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(int goalId, int progress) async {
    try {
      await _repository.updateProgress(goalId, progress);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}