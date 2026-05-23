import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/focus_timer/domain/focus_timer_session.dart';

final focusTimerRepositoryProvider = Provider<FocusTimerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return FocusTimerRepository(dbAsync);
});

class FocusTimerRepository {
  final AsyncValue<Database> _dbAsync;

  FocusTimerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insert(FocusTimerSession session) async {
    final db = await _db;
    return await db.insert('focus_timer_sessions', session.toMap());
  }

  Future<int> update(FocusTimerSession session) async {
    final db = await _db;
    return await db.update(
      'focus_timer_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<FocusTimerSession>> getRecent(int limit) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_timer_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((map) => FocusTimerSession.fromMap(map)).toList();
  }

  Future<List<FocusTimerSession>> getTodaySessions() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'focus_timer_sessions',
      where: 'date(started_at) = ?',
      whereArgs: [today],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => FocusTimerSession.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as session_count,
        SUM(duration_minutes) as total_minutes,
        SUM(interruption_count) as total_interruptions
      FROM focus_timer_sessions
      WHERE date(started_at) = ? AND is_completed = 1
    ''', [today]);

    final sessions = result.first;
    return {
      'sessionCount': sessions['session_count'] as int? ?? 0,
      'totalMinutes': sessions['total_minutes'] as int? ?? 0,
      'totalInterruptions': sessions['total_interruptions'] as int? ?? 0,
    };
  }

  Future<Map<String, dynamic>> getWeekStats() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as session_count,
        SUM(duration_minutes) as total_minutes,
        AVG(duration_minutes) as avg_duration
      FROM focus_timer_sessions
      WHERE started_at >= datetime('now', '-7 days') AND is_completed = 1
    ''');

    final sessions = result.first;
    return {
      'sessionCount': sessions['session_count'] as int? ?? 0,
      'totalMinutes': sessions['total_minutes'] as int? ?? 0,
      'avgDuration': (sessions['avg_duration'] as num?)?.toDouble() ?? 0,
    };
  }
}
