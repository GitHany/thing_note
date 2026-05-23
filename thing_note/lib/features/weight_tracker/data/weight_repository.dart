import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weight_tracker/domain/weight_record.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return WeightRepository(dbAsync);
});

final weightRecordsProvider = StateNotifierProvider<WeightRecordsNotifier, AsyncValue<List<WeightRecord>>>((ref) {
  final repository = ref.watch(weightRepositoryProvider);
  return WeightRecordsNotifier(repository);
});

final weightGoalProvider = StateNotifierProvider<WeightGoalNotifier, AsyncValue<WeightGoal?>>((ref) {
  final repository = ref.watch(weightRepositoryProvider);
  return WeightGoalNotifier(repository);
});

final latestWeightProvider = Provider<AsyncValue<WeightRecord?>>((ref) {
  final records = ref.watch(weightRecordsProvider);
  return records.whenData((list) => list.isNotEmpty ? list.first : null);
});

class WeightRepository {
  final AsyncValue<Database> _dbAsync;

  WeightRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertWeightRecord(WeightRecord record) async {
    final db = await _db;
    return db.insert('weight_records', record.toMap());
  }

  Future<int> deleteWeightRecord(int id) async {
    final db = await _db;
    return db.delete('weight_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WeightRecord>> getAllWeightRecords() async {
    final db = await _db;
    final maps = await db.query('weight_records', orderBy: 'recorded_at DESC');
    return maps.map((m) => WeightRecord.fromMap(m)).toList();
  }

  Future<List<WeightRecord>> getWeightRecordsInRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'weight_records',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => WeightRecord.fromMap(m)).toList();
  }

  Future<WeightRecord?> getLatestWeightRecord() async {
    final db = await _db;
    final maps = await db.query('weight_records', orderBy: 'recorded_at DESC', limit: 1);
    if (maps.isEmpty) return null;
    return WeightRecord.fromMap(maps.first);
  }

  Future<int> insertWeightGoal(WeightGoal goal) async {
    final db = await _db;
    // Deactivate existing goals
    await db.update('weight_goals', {'is_active': 0}, where: 'is_active = 1');
    return db.insert('weight_goals', goal.toMap());
  }

  Future<WeightGoal?> getActiveWeightGoal() async {
    final db = await _db;
    final maps = await db.query('weight_goals', where: 'is_active = 1', limit: 1);
    if (maps.isEmpty) return null;
    return WeightGoal.fromMap(maps.first);
  }

  Future<int> deactivateWeightGoals() async {
    final db = await _db;
    return db.update('weight_goals', {'is_active': 0});
  }
}

class WeightRecordsNotifier extends StateNotifier<AsyncValue<List<WeightRecord>>> {
  final WeightRepository _repository;

  WeightRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getAllWeightRecords();
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    try {
      await _repository.insertWeightRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWeightRecord(int id) async {
    try {
      await _repository.deleteWeightRecord(id);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class WeightGoalNotifier extends StateNotifier<AsyncValue<WeightGoal?>> {
  final WeightRepository _repository;

  WeightGoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoal();
  }

  Future<void> loadGoal() async {
    state = const AsyncValue.loading();
    try {
      final goal = await _repository.getActiveWeightGoal();
      state = AsyncValue.data(goal);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setWeightGoal(WeightGoal goal) async {
    try {
      await _repository.insertWeightGoal(goal);
      await loadGoal();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearGoal() async {
    try {
      await _repository.deactivateWeightGoals();
      await loadGoal();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}