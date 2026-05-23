import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_mode/domain/focus_session.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return FocusRepository(dbAsync);
});

final focusSessionsProvider = StateNotifierProvider<FocusSessionsNotifier, AsyncValue<List<FocusSession>>>((ref) {
  final repository = ref.watch(focusRepositoryProvider);
  return FocusSessionsNotifier(repository);
});

final focusStatsProvider = FutureProvider<FocusStats>((ref) async {
  final repository = ref.watch(focusRepositoryProvider);
  return repository.getFocusStats();
});

final currentFocusProvider = StateProvider<FocusSession?>((ref) => null);

final focusTimerProvider = StateProvider<int>((ref) => 0);

class FocusRepository {
  final AsyncValue<Database> _dbAsync;

  FocusRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSession(FocusSession session) async {
    final db = await _db;
    return db.insert('focus_sessions', session.toMap());
  }

  Future<int> updateSession(FocusSession session) async {
    final db = await _db;
    return db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await _db;
    return db.delete('focus_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FocusSession>> getAllSessions() async {
    final db = await _db;
    final maps = await db.query('focus_sessions', orderBy: 'started_at DESC');
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  Future<List<FocusSession>> getSessionsForDate(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final maps = await db.query(
      'focus_sessions',
      where: 'started_at >= ? AND started_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  Future<void> completeSession(int sessionId) async {
    final db = await _db;
    await db.update(
      'focus_sessions',
      {
        'ended_at': DateTime.now().toIso8601String(),
        'is_completed': 1,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<FocusStats> getFocusStats() async {
    final db = await _db;
    final now = DateTime.now();
    
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    Future<Map<String, int>> getStatsForPeriod(DateTime start, DateTime end) async {
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as sessions,
          COALESCE(SUM(duration_minutes), 0) as minutes
        FROM focus_sessions 
        WHERE started_at >= ? AND started_at < ? AND is_completed = 1
      ''', [start.toIso8601String(), end.toIso8601String()]);
      
      if (result.isEmpty) {
        return {'sessions': 0, 'minutes': 0};
      }
      return {
        'sessions': result.first['sessions'] as int? ?? 0,
        'minutes': result.first['minutes'] as int? ?? 0,
      };
    }
    
    final todayStats = await getStatsForPeriod(todayStart, todayStart.add(const Duration(days: 1)));
    final weekStats = await getStatsForPeriod(weekStart, now.add(const Duration(days: 1)));
    final monthStats = await getStatsForPeriod(monthStart, now.add(const Duration(days: 1)));
    
    return FocusStats(
      todayMinutes: todayStats['minutes'] ?? 0,
      todaySessions: todayStats['sessions'] ?? 0,
      weekMinutes: weekStats['minutes'] ?? 0,
      weekSessions: weekStats['sessions'] ?? 0,
      monthMinutes: monthStats['minutes'] ?? 0,
      monthSessions: monthStats['sessions'] ?? 0,
    );
  }
}

class FocusSessionsNotifier extends StateNotifier<AsyncValue<List<FocusSession>>> {
  final FocusRepository _repository;

  FocusSessionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repository.getAllSessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FocusSession> startSession(String title, int durationMinutes) async {
    final session = FocusSession(
      title: title,
      durationMinutes: durationMinutes,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    final id = await _repository.insertSession(session);
    await loadSessions();
    
    return session.copyWith(id: id);
  }

  Future<void> completeSession(int sessionId) async {
    try {
      await _repository.completeSession(sessionId);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      await _repository.deleteSession(id);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}