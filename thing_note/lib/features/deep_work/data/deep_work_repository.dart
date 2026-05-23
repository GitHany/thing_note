import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/deep_work/domain/deep_work_model.dart';

final deepWorkRepositoryProvider = Provider<DeepWorkRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DeepWorkRepository(dbAsync);
});

class DeepWorkRepository {
  final AsyncValue<Database> _dbAsync;

  DeepWorkRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> startSession(DeepWorkSessionModel session) async {
    final db = await _db;
    return await db.insert('deep_work_sessions', {
      'started_at': session.startedAt.toIso8601String(),
      'ended_at': null,
      'duration_minutes': 0,
      'focus_score': 0,
      'distraction_count': 0,
      'linked_record_id': session.linkedRecordId,
      'note': session.note,
      'created_at': session.createdAt.toIso8601String(),
    });
  }

  Future<void> endSession({
    required int id,
    required DateTime endedAt,
    required int durationMinutes,
    required int focusScore,
    required int distractionCount,
    String? note,
  }) async {
    final db = await _db;
    await db.update(
      'deep_work_sessions',
      {
        'ended_at': endedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'focus_score': focusScore,
        'distraction_count': distractionCount,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DeepWorkSessionModel>> getAllSessions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => DeepWorkSessionModel.fromMap(map)).toList();
  }

  Future<List<DeepWorkSessionModel>> getRecentSessions({int limit = 10}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((map) => DeepWorkSessionModel.fromMap(map)).toList();
  }

  Future<List<DeepWorkSessionModel>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      where: 'started_at >= ? AND started_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => DeepWorkSessionModel.fromMap(map)).toList();
  }

  Future<List<DeepWorkSessionModel>> getCompletedSessions({
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      where: 'ended_at IS NOT NULL',
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => DeepWorkSessionModel.fromMap(map)).toList();
  }

  Future<DeepWorkSessionModel?> getActiveSession() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DeepWorkSessionModel.fromMap(maps.first);
  }

  Future<int> deleteSession(int id) async {
    final db = await _db;
    return await db.delete(
      'deep_work_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getStatsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> sessions = await db.query(
      'deep_work_sessions',
      where: 'started_at >= ? AND started_at <= ? AND ended_at IS NOT NULL',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    int totalMinutes = 0;
    int totalFocusScore = 0;
    int totalDistraction = 0;

    for (final session in sessions) {
      totalMinutes += (session['duration_minutes'] as int?) ?? 0;
      totalFocusScore += (session['focus_score'] as int?) ?? 0;
      totalDistraction += (session['distraction_count'] as int?) ?? 0;
    }

    return {
      'session_count': sessions.length,
      'total_minutes': totalMinutes,
      'avg_focus_score': sessions.isNotEmpty ? totalFocusScore ~/ sessions.length : 0,
      'avg_distraction': sessions.isNotEmpty ? totalDistraction ~/ sessions.length : 0,
    };
  }

  Future<List<Map<String, dynamic>>> getDailyStats({int days = 7}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < days; i++) {
      final dayStart = startDate.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final stats = await getStatsByDateRange(dayStart, dayEnd);
      result.add({
        'date': dayStart.toIso8601String().substring(0, 10),
        ...stats,
      });
    }

    return result;
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return await getStatsByDateRange(weekStart, weekEnd);
  }

  Future<Map<String, dynamic>> getMonthlySummary() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    return await getStatsByDateRange(monthStart, monthEnd);
  }

  Future<List<DeepWorkSessionModel>> searchSessions(String query) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      where: 'note LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => DeepWorkSessionModel.fromMap(map)).toList();
  }

  Future<List<DeepWorkSessionModel>> getSessionsByFocusScore({
    required int minScore,
    required int maxScore,
  }) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'deep_work_sessions',
      where: 'focus_score >= ? AND focus_score <= ? AND ended_at IS NOT NULL',
      whereArgs: [minScore, maxScore],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => DeepWorkSessionModel.fromMap(map)).toList();
  }
}
