import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_stacking/domain/habit_chain.dart';

final habitStackingRepositoryProvider = Provider<HabitStackingRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitStackingRepository(dbAsync);
});

final habitChainsProvider = StateNotifierProvider<HabitChainsNotifier, AsyncValue<List<HabitChain>>>((ref) {
  final repository = ref.watch(habitStackingRepositoryProvider);
  return HabitChainsNotifier(repository);
});

class HabitStackingRepository {
  final AsyncValue<Database> _dbAsync;

  HabitStackingRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertChain(HabitChain chain) async {
    final db = await _db;
    return db.insert('habit_chains', chain.toMap());
  }

  Future<int> updateChain(HabitChain chain) async {
    final db = await _db;
    return db.update('habit_chains', chain.toMap(), where: 'id = ?', whereArgs: [chain.id]);
  }

  Future<int> deleteChain(int id) async {
    final db = await _db;
    return db.delete('habit_chains', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitChain>> getAllChains() async {
    final db = await _db;
    final maps = await db.query('habit_chains', orderBy: 'created_at DESC');
    return maps.map((m) => HabitChain.fromMap(m)).toList();
  }

  Future<List<HabitChain>> getActiveChains() async {
    final db = await _db;
    final maps = await db.query(
      'habit_chains',
      where: 'completion_count > 0',
      orderBy: 'completion_count DESC',
    );
    return maps.map((m) => HabitChain.fromMap(m)).toList();
  }

  Future<void> incrementCompletion(int chainId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE habit_chains SET completion_count = completion_count + 1 WHERE id = ?',
      [chainId],
    );
  }

  Future<Map<String, dynamic>> getChainStats() async {
    final db = await _db;
    final totalChains = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM habit_chains'),
    ) ?? 0;
    final totalCompletions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(completion_count) FROM habit_chains'),
    ) ?? 0;
    return {
      'total_chains': totalChains,
      'total_completions': totalCompletions,
    };
  }

  static const List<Map<String, dynamic>> templates = [
    {
      'name': '晨间习惯链',
      'habits': ['起床', '喝水', '冥想', '运动', '早餐'],
    },
    {
      'name': '晚间习惯链',
      'habits': ['晚餐', '散步', '阅读', '写日记', '睡觉'],
    },
    {
      'name': '工作前准备链',
      'habits': ['整理桌面', '查看日程', '设置目标', '开始工作'],
    },
    {
      'name': '健身准备链',
      'habits': ['换衣服', '准备装备', '热身', '开始训练'],
    },
  ];
}

class HabitChainsNotifier extends StateNotifier<AsyncValue<List<HabitChain>>> {
  final HabitStackingRepository _repository;

  HabitChainsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadChains();
  }

  Future<void> loadChains() async {
    state = const AsyncValue.loading();
    try {
      final chains = await _repository.getAllChains();
      state = AsyncValue.data(chains);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addChain(HabitChain chain) async {
    try {
      await _repository.insertChain(chain);
      await loadChains();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateChain(HabitChain chain) async {
    try {
      await _repository.updateChain(chain);
      await loadChains();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteChain(int id) async {
    try {
      await _repository.deleteChain(id);
      await loadChains();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeChain(int chainId) async {
    try {
      await _repository.incrementCompletion(chainId);
      await loadChains();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}