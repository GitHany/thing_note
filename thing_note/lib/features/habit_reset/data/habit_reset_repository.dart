import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_reset/domain/habit_reset.dart';

final habitResetRepositoryProvider = Provider<HabitResetRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitResetRepository(dbAsync);
});

final habitResetsProvider = StateNotifierProvider<HabitResetsNotifier, AsyncValue<List<HabitReset>>>((ref) {
  final repository = ref.watch(habitResetRepositoryProvider);
  return HabitResetsNotifier(repository);
});

class HabitResetRepository {
  final AsyncValue<Database> _dbAsync;

  HabitResetRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertReset(HabitReset reset) async {
    final db = await _db;
    return db.insert('habit_resets', reset.toMap());
  }

  Future<List<HabitReset>> getResetsByHabit(int habitId) async {
    final db = await _db;
    final maps = await db.query(
      'habit_resets',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'reset_date DESC',
    );
    return maps.map((m) => HabitReset.fromMap(m)).toList();
  }

  Future<List<HabitReset>> getRecentResets(int days) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'habit_resets',
      where: 'reset_date >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'reset_date DESC',
    );
    return maps.map((m) => HabitReset.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final totalResets = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM habit_resets'),
    ) ?? 0;
    
    final softResets = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM habit_resets WHERE is_soft_reset = 1'),
    ) ?? 0;
    
    final hardResets = totalResets - softResets;
    
    final reasonDistribution = <String, int>{};
    for (final reason in HabitReset.resetReasons) {
      reasonDistribution[reason] = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM habit_resets WHERE reset_reason = ?',
          [reason],
        ),
      ) ?? 0;
    }
    
    return {
      'total_resets': totalResets,
      'soft_resets': softResets,
      'hard_resets': hardResets,
      'reason_distribution': reasonDistribution,
    };
  }

  Future<List<Map<String, dynamic>>> getMostResetHabits() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT habit_id, COUNT(*) as reset_count,
             SUM(CASE WHEN is_soft_reset = 1 THEN 1 ELSE 0 END) as soft_count
      FROM habit_resets
      GROUP BY habit_id
      ORDER BY reset_count DESC
      LIMIT 10
    ''');
    return result;
  }
}

class HabitResetsNotifier extends StateNotifier<AsyncValue<List<HabitReset>>> {
  final HabitResetRepository _repository;

  HabitResetsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadResets();
  }

  Future<void> loadResets() async {
    state = const AsyncValue.loading();
    try {
      final resets = await _repository.getRecentResets(30);
      state = AsyncValue.data(resets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordReset(int habitId, String reason, int previousStreak, {bool isSoft = false}) async {
    try {
      final reset = HabitReset(
        habitId: habitId,
        resetReason: reason,
        resetDate: DateTime.now().toIso8601String(),
        previousStreak: previousStreak,
        newStreak: 0,
        isSoftReset: isSoft ? 1 : 0,
      );
      await _repository.insertReset(reset);
      await loadResets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<HabitReset>> getResetsForHabit(int habitId) async {
    return _repository.getResetsByHabit(habitId);
  }
}