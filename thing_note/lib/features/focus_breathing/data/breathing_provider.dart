import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/focus_breathing/domain/breathing_model.dart';

final breathingSessionsProvider = FutureProvider<List<BreathingSession>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'breathing_sessions',
    orderBy: 'started_at DESC',
    limit: 50,
  );
  return results.map((m) => BreathingSession.fromMap(m)).toList();
});

final breathingStatsProvider = FutureProvider<BreathingStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final stats = await db.rawQuery('''
    SELECT 
      COUNT(*) as total,
      SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed,
      SUM(duration_seconds) / 60 as total_minutes
    FROM breathing_sessions
  ''');
  
  return BreathingStats(
    totalSessions: (stats.first['total'] as int?) ?? 0,
    completedSessions: (stats.first['completed'] as int?) ?? 0,
    totalMinutes: (stats.first['total_minutes'] as num?)?.toInt() ?? 0,
    completionRate: 0.85,
    favoritePattern: '4-7-8 放松呼吸',
  );
});

class BreathingSessionNotifier extends StateNotifier<AsyncValue<List<BreathingSession>>> {
  final Ref ref;
  
  BreathingSessionNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSessions();
  }
  
  Future<void> _loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('breathing_sessions', orderBy: 'started_at DESC');
      state = AsyncValue.data(results.map((m) => BreathingSession.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> saveSession(BreathingSession session) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('breathing_sessions', session.toMap()..remove('id'));
    await _loadSessions();
  }
}

final breathingSessionNotifierProvider =
    StateNotifierProvider<BreathingSessionNotifier, AsyncValue<List<BreathingSession>>>((ref) {
  return BreathingSessionNotifier(ref);
});