import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/study_timer/domain/study_session.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final studySessionRepositoryProvider = Provider<StudySessionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return StudySessionRepository(dbAsync);
});

final studySessionsProvider = StateNotifierProvider<StudySessionsNotifier, AsyncValue<List<StudySession>>>((ref) {
  final repository = ref.watch(studySessionRepositoryProvider);
  return StudySessionsNotifier(repository);
});

final todayStudyMinutesProvider = Provider<AsyncValue<int>>((ref) {
  final sessions = ref.watch(studySessionsProvider);
  return sessions.whenData((list) {
    final today = DateTime.now();
    final todaySessions = list.where((s) =>
        s.startedAt.year == today.year &&
        s.startedAt.month == today.month &&
        s.startedAt.day == today.day &&
        s.isCompleted);
    return todaySessions.fold(0, (sum, s) => sum + s.durationMinutes);
  });
});

final weeklyStudyMinutesProvider = Provider<AsyncValue<int>>((ref) {
  final sessions = ref.watch(studySessionsProvider);
  return sessions.whenData((list) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekSessions = list.where((s) =>
        s.startedAt.isAfter(weekStart) && s.isCompleted);
    return weekSessions.fold(0, (sum, s) => sum + s.durationMinutes);
  });
});

class StudySessionRepository {
  final AsyncValue<Database> _dbAsync;

  StudySessionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertStudySession(StudySession session) async {
    final db = await _db;
    return db.insert('study_sessions', session.toMap());
  }

  Future<int> updateStudySession(StudySession session) async {
    final db = await _db;
    return db.update('study_sessions', session.toMap(),
        where: 'id = ?', whereArgs: [session.id]);
  }

  Future<int> deleteStudySession(int id) async {
    final db = await _db;
    return db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StudySession>> getAllStudySessions() async {
    final db = await _db;
    final maps = await db.query('study_sessions', orderBy: 'started_at DESC');
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  Future<List<StudySession>> getStudySessionsByDate(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'study_sessions',
      where: 'started_at >= ? AND started_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  Future<StudySession?> getActiveSession() async {
    final db = await _db;
    final maps = await db.query(
      'study_sessions',
      where: 'status = ?',
      whereArgs: [SessionStatus.inProgress.name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return StudySession.fromMap(maps.first);
  }
}

class StudySessionsNotifier extends StateNotifier<AsyncValue<List<StudySession>>> {
  final StudySessionRepository _repository;

  StudySessionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repository.getAllStudySessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSession(StudySession session) async {
    try {
      await _repository.insertStudySession(session);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeSession(StudySession session) async {
    try {
      final completed = session.copyWith(
        endedAt: DateTime.now(),
        status: SessionStatus.completed,
      );
      await _repository.updateStudySession(completed);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelSession(StudySession session) async {
    try {
      final cancelled = session.copyWith(
        endedAt: DateTime.now(),
        status: SessionStatus.cancelled,
      );
      await _repository.updateStudySession(cancelled);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      await _repository.deleteStudySession(id);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}