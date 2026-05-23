import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/break_timer/domain/break_session.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final breakTimerRepositoryProvider = Provider<BreakTimerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return BreakTimerRepository(dbAsync);
});

final breakSuggestionsProvider = Provider<List<BreakSuggestion>>((ref) {
  return BreakSuggestion.defaults;
});

class BreakTimerRepository {
  final AsyncValue<Database> _dbAsync;

  BreakTimerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> startBreak(BreakSession session) async {
    final db = await _db;
    return db.insert('break_sessions', session.toMap());
  }

  Future<int> endBreak(int id, BreakSession session) async {
    final db = await _db;
    return db.update(
      'break_sessions',
      session.copyWith(endedAt: DateTime.now(), durationMinutes: session.durationMinutes).toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<BreakSession?> getActiveBreak() async {
    final db = await _db;
    final maps = await db.query(
      'break_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BreakSession.fromMap(maps.first);
  }

  Future<List<BreakSession>> getBreaksForDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'break_sessions',
      where: 'date(started_at) = ?',
      whereArgs: [date],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => BreakSession.fromMap(m)).toList();
  }

  Future<Map<String, int>> getTodayBreakStats(String date) async {
    final breaks = await getBreaksForDate(date);
    int totalMinutes = 0;
    int microBreaks = 0;
    for (final b in breaks) {
      totalMinutes += b.durationMinutes;
      if (b.isMicroBreak) microBreaks++;
    }
    return {
      'total_sessions': breaks.length,
      'total_minutes': totalMinutes,
      'micro_breaks': microBreaks,
    };
  }

  Future<List<BreakSession>> getBreaksForWeek(String endDate) async {
    final db = await _db;
    final end = DateTime.parse(endDate);
    final start = end.subtract(const Duration(days: 6));
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'break_sessions',
      where: 'date(started_at) BETWEEN ? AND ?',
      whereArgs: [startStr, endDate],
      orderBy: 'started_at ASC',
    );
    return maps.map((m) => BreakSession.fromMap(m)).toList();
  }
}
