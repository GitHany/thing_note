import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_notification_timing/domain/timing_model.dart';

final timingStatsProvider = FutureProvider<TimingStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final results = await db.query('notification_timing_rules');
  
  return TimingStats(
    totalRules: results.length,
    averageResponseRate: 0.78,
    bestTiming: '上午 9:00',
    rules: results.map((m) => NotificationTimingRule.fromMap(m)).toList(),
  );
});

class TimingNotifier extends StateNotifier<AsyncValue<List<NotificationTimingRule>>> {
  final Ref ref;
  
  TimingNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadRules();
  }
  
  Future<void> _loadRules() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('notification_timing_rules', orderBy: 'response_rate DESC');
      state = AsyncValue.data(results.map((m) => NotificationTimingRule.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addRule(String type, int hour, int minute) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('notification_timing_rules', {
      'notification_type': type,
      'optimal_hour': hour,
      'optimal_minute': minute,
      'response_rate': 0.5,
      'sample_count': 0,
    });
    await _loadRules();
  }
  
  Future<void> updateRule(NotificationTimingRule rule) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'notification_timing_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
    await _loadRules();
  }
  
  Future<void> deleteRule(int ruleId) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete(
      'notification_timing_rules',
      where: 'id = ?',
      whereArgs: [ruleId],
    );
    await _loadRules();
  }
}

final timingNotifierProvider =
    StateNotifierProvider<TimingNotifier, AsyncValue<List<NotificationTimingRule>>>((ref) {
  return TimingNotifier(ref);
});