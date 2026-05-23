import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/pomodoro_timer/domain/pomodoro_session.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final pomodoroRepositoryProvider = Provider<PomodoroRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PomodoroRepository(dbAsync);
});

final pomodoroTodayProvider = FutureProvider<PomodoroStats>((ref) async {
  final repo = ref.watch(pomodoroRepositoryProvider);
  return repo.getStatsByDate(_todayDate());
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class PomodoroRepository {
  final AsyncValue<Database> _dbAsync;

  PomodoroRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSession(PomodoroSession session) async {
    final db = await _db;
    return db.insert('pomodoro_sessions', session.toMap());
  }

  Future<int> updateSession(PomodoroSession session) async {
    final db = await _db;
    return db.update('pomodoro_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<PomodoroSession?> getActiveSession() async {
    final db = await _db;
    final maps = await db.query(
      'pomodoro_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PomodoroSession.fromMap(maps.first);
  }

  Future<List<PomodoroSession>> getSessionsForDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'pomodoro_sessions',
      where: "date(started_at) = ? AND session_type = 'focus'",
      whereArgs: [date],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => PomodoroSession.fromMap(m)).toList();
  }

  Future<PomodoroStats> getStatsByDate(String date) async {
    final db = await _db;
    final maps = await db.query('pomodoro_stats', where: 'date = ?', whereArgs: [date]);
    if (maps.isNotEmpty) return PomodoroStats.fromMap(maps.first);
    return PomodoroStats(date: date, createdAt: DateTime.now());
  }

  Future<int> upsertStats(PomodoroStats stats) async {
    final db = await _db;
    final existing = await db.query('pomodoro_stats', where: 'date = ?', whereArgs: [stats.date]);
    if (existing.isNotEmpty) {
      return db.update('pomodoro_stats', stats.toMap(), where: 'id = ?', whereArgs: [existing.first['id']]);
    }
    return db.insert('pomodoro_stats', stats.toMap());
  }

  Future<Map<String, int>> getTodaySummary(String date) async {
    final sessions = await getSessionsForDate(date);
    int totalMinutes = 0;
    for (final s in sessions) {
      totalMinutes += s.totalDurationMinutes;
    }
    return {
      'sessions': sessions.length,
      'focus_minutes': totalMinutes,
      'completed_rounds': sessions.fold(0, (sum, s) => sum + s.roundsCompleted),
    };
  }

  Future<List<PomodoroSession>> getSessionsForWeek(String endDate) async {
    final db = await _db;
    final end = DateTime.parse(endDate);
    final start = end.subtract(const Duration(days: 6));
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'pomodoro_sessions',
      where: "date(started_at) BETWEEN ? AND ? AND session_type = 'focus'",
      whereArgs: [startStr, endDate],
      orderBy: 'started_at ASC',
    );
    return maps.map((m) => PomodoroSession.fromMap(m)).toList();
  }
}
