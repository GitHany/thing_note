import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_chaining/domain/habit_chain_model.dart';

final habitChainsProvider = FutureProvider<List<HabitChain>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('habit_chains', orderBy: 'completion_count DESC');
  return results.map((m) => HabitChain.fromMap(m)).toList();
});

final chainRecommendationsProvider = FutureProvider<List<ChainRecommendation>>((ref) async {
  // 模拟推荐数据
  return [
    ChainRecommendation(
      habitId: 1,
      suggestedNextHabitId: 2,
      reason: '时间接近，适合连续完成',
      confidence: 0.85,
      chainType: 'time',
    ),
    ChainRecommendation(
      habitId: 3,
      suggestedNextHabitId: 4,
      reason: '同一地点的习惯链',
      confidence: 0.78,
      chainType: 'location',
    ),
  ];
});

class HabitChainNotifier extends StateNotifier<AsyncValue<List<HabitChain>>> {
  final Ref ref;
  
  HabitChainNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadChains();
  }
  
  Future<void> _loadChains() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('habit_chains', orderBy: 'completion_count DESC');
      state = AsyncValue.data(results.map((m) => HabitChain.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addChain(String name, List<int> habitIds, String chainType) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('habit_chains', {
      'chain_name': name,
      'habit_ids': habitIds.join(','),
      'chain_type': chainType,
      'completion_count': 0,
      'success_rate': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _loadChains();
  }
  
  Future<void> recordChainCompletion(int chainId) async {
    final db = await ref.read(databaseProvider.future);
    await db.rawUpdate(
      'UPDATE habit_chains SET completion_count = completion_count + 1 WHERE id = ?',
      [chainId],
    );
    await _loadChains();
  }
}

final habitChainNotifierProvider =
    StateNotifierProvider<HabitChainNotifier, AsyncValue<List<HabitChain>>>((ref) {
  return HabitChainNotifier(ref);
});