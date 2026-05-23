import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/daily_achievements/domain/daily_challenge_model.dart';

final dailyChallengesProvider = FutureProvider<List<DailyChallenge>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  final results = await db.query(
    'daily_challenges',
    where: 'challenge_date = ?',
    whereArgs: [todayStr],
    orderBy: 'is_completed ASC',
  );
  return results.map((m) => DailyChallenge.fromMap(m)).toList();
});

class DailyAchievementNotifier extends StateNotifier<AsyncValue<List<DailyChallenge>>> {
  final Ref ref;
  
  DailyAchievementNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadChallenges();
  }
  
  Future<void> _loadChallenges() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final results = await db.query(
        'daily_challenges',
        where: 'challenge_date = ?',
        whereArgs: [todayStr],
      );
      state = AsyncValue.data(results.map((m) => DailyChallenge.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> completeChallenge(int challengeId) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'daily_challenges',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [challengeId],
    );
    await _loadChallenges();
  }
  
  Future<void> updateProgress(int challengeId, int value) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'daily_challenges',
      {'current_value': value},
      where: 'id = ?',
      whereArgs: [challengeId],
    );
    await _loadChallenges();
  }
}

final dailyAchievementNotifierProvider =
    StateNotifierProvider<DailyAchievementNotifier, AsyncValue<List<DailyChallenge>>>((ref) {
  return DailyAchievementNotifier(ref);
});