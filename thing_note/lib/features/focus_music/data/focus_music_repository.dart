import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/focus_music/domain/focus_music.dart';

final focusMusicRepositoryProvider = Provider<FocusMusicRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return FocusMusicRepository(dbAsync);
});

final focusMusicSessionsProvider = StateNotifierProvider<FocusMusicSessionsNotifier, AsyncValue<List<FocusMusicSession>>>((ref) {
  final repository = ref.watch(focusMusicRepositoryProvider);
  return FocusMusicSessionsNotifier(repository);
});

final currentMusicSessionProvider = StateProvider<FocusMusicSession?>((ref) => null);

class FocusMusicRepository {
  final AsyncValue<Database> _dbAsync;

  FocusMusicRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSession(FocusMusicSession session) async {
    final db = await _db;
    return db.insert('focus_music_sessions', session.toMap());
  }

  Future<int> updateSession(FocusMusicSession session) async {
    final db = await _db;
    return db.update('focus_music_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<List<FocusMusicSession>> getSessionsByDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'focus_music_sessions',
      where: 'started_at LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => FocusMusicSession.fromMap(m)).toList();
  }

  Future<List<FocusMusicSession>> getRecentSessions(int days) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'focus_music_sessions',
      where: 'started_at >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => FocusMusicSession.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getSceneStats() async {
    final db = await _db;
    final result = <String, dynamic>{};
    
    for (final scene in FocusMusicSession.sceneTypes) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM focus_music_sessions WHERE scene_type = ?',
          [scene],
        ),
      ) ?? 0;
      final totalMinutes = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT SUM(duration_minutes) FROM focus_music_sessions WHERE scene_type = ?',
          [scene],
        ),
      ) ?? 0;
      result[scene] = {'count': count, 'minutes': totalMinutes};
    }
    
    return result;
  }

  Future<List<String>> getFavoritePlaylists() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT playlist_name, COUNT(*) as use_count 
      FROM focus_music_sessions 
      WHERE playlist_name IS NOT NULL 
      GROUP BY playlist_name 
      ORDER BY use_count DESC 
      LIMIT 5
    ''');
    return maps.map((m) => m['playlist_name'] as String).toList();
  }
}

class FocusMusicSessionsNotifier extends StateNotifier<AsyncValue<List<FocusMusicSession>>> {
  final FocusMusicRepository _repository;

  FocusMusicSessionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repository.getRecentSessions(7);
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSession(String sceneType, {String? playlistName}) async {
    try {
      final session = FocusMusicSession(
        sceneType: sceneType,
        playlistName: playlistName,
        startedAt: DateTime.now(),
      );
      await _repository.insertSession(session);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession(FocusMusicSession session) async {
    try {
      final endedAt = DateTime.now();
      final duration = endedAt.difference(session.startedAt).inMinutes;
      final updated = session.copyWith(endedAt: endedAt, durationMinutes: duration);
      await _repository.updateSession(updated);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}