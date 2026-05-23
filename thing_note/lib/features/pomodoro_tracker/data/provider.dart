import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/models.dart';

final pomodoroTrackerRepositoryProvider = Provider<PomodoroTrackerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PomodoroTrackerRepository(dbAsync);
});

final pomodoroSessionsProvider = StateNotifierProvider<PomodoroSessionsNotifier, List<PomodoroSession>>((ref) {
  final repository = ref.watch(pomodoroTrackerRepositoryProvider);
  return PomodoroSessionsNotifier(repository);
});

final todayPomodoroCountProvider = Provider<int>((ref) {
  final sessions = ref.watch(pomodoroSessionsProvider);
  final today = DateTime.now();
  return sessions
    .where((s) => s.startedAt.year == today.year && s.startedAt.month == today.month && s.startedAt.day == today.day)
    .fold(0, (sum, s) => sum + s.completedPomodoros);
});

class PomodoroTrackerRepository {
  final AsyncValue<Database> _dbAsync;

  PomodoroTrackerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<Map<String, dynamic>>> querySessions() async {
    final db = await _db;
    return await db.query('pomodoro_sessions', orderBy: 'started_at DESC');
  }

  Future<int> insertSession(Map<String, dynamic> sessionMap) async {
    final db = await _db;
    return await db.insert('pomodoro_sessions', sessionMap);
  }

  Future<void> updateSession(PomodoroSession session) async {
    final db = await _db;
    await db.update('pomodoro_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> completeSession(int sessionId, int completedPomodoros, int totalMinutes) async {
    final db = await _db;
    await db.update(
      'pomodoro_sessions',
      {
        'completed_at': DateTime.now().toIso8601String(),
        'completed_pomodoros': completedPomodoros,
        'total_minutes': totalMinutes,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSession(int id) async {
    final db = await _db;
    await db.delete('pomodoro_sessions', where: 'id = ?', whereArgs: [id]);
  }
}

class PomodoroSessionsNotifier extends StateNotifier<List<PomodoroSession>> {
  final PomodoroTrackerRepository _repository;

  PomodoroSessionsNotifier(this._repository) : super([]) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    final maps = await _repository.querySessions();
    state = maps.map((m) => PomodoroSession.fromMap(m)).toList();
  }

  Future<int> startSession(PomodoroSession session) async {
    final id = await _repository.insertSession(session.toMap()..remove('id'));
    await loadSessions();
    return id;
  }

  Future<void> updateSession(PomodoroSession session) async {
    await _repository.updateSession(session);
    await loadSessions();
  }

  Future<void> completeSession(int sessionId, int completedPomodoros, int totalMinutes) async {
    await _repository.completeSession(sessionId, completedPomodoros, totalMinutes);
    await loadSessions();
  }

  Future<void> deleteSession(int id) async {
    await _repository.deleteSession(id);
    await loadSessions();
  }
}
