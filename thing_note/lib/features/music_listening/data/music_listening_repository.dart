import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/music_listening/domain/music_listening.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final musicListeningRepositoryProvider = Provider<MusicListeningRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MusicListeningRepository(dbAsync);
});

final musicListeningProvider = StateNotifierProvider<MusicListeningNotifier, AsyncValue<List<MusicListening>>>((ref) {
  final repository = ref.watch(musicListeningRepositoryProvider);
  return MusicListeningNotifier(repository);
});

final topArtistsProvider = Provider<AsyncValue<List<MapEntry<String, int>>>>((ref) {
  final listening = ref.watch(musicListeningProvider);
  return listening.whenData((list) {
    final artistCounts = <String, int>{};
    for (final item in list) {
      if (item.artist != null && item.artist!.isNotEmpty) {
        artistCounts[item.artist!] = (artistCounts[item.artist!] ?? 0) + 1;
      }
    }
    final sorted = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  });
});

class MusicListeningRepository {
  final AsyncValue<Database> _dbAsync;

  MusicListeningRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMusicListening(MusicListening listening) async {
    final db = await _db;
    return db.insert('music_listening', listening.toMap());
  }

  Future<int> deleteMusicListening(int id) async {
    final db = await _db;
    return db.delete('music_listening', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MusicListening>> getAllMusicListening() async {
    final db = await _db;
    final maps = await db.query('music_listening', orderBy: 'listened_at DESC');
    return maps.map((m) => MusicListening.fromMap(m)).toList();
  }

  Future<List<MusicListening>> getRecentListening({int limit = 20}) async {
    final db = await _db;
    final maps = await db.query(
      'music_listening',
      orderBy: 'listened_at DESC',
      limit: limit,
    );
    return maps.map((m) => MusicListening.fromMap(m)).toList();
  }

  Future<List<MusicListening>> searchMusic(String query) async {
    final db = await _db;
    final maps = await db.query(
      'music_listening',
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'listened_at DESC',
    );
    return maps.map((m) => MusicListening.fromMap(m)).toList();
  }

  Future<int> getTotalListeningMinutes() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(duration_seconds) as total FROM music_listening',
    );
    final total = result.first['total'] as int? ?? 0;
    return total ~/ 60;
  }
}

class MusicListeningNotifier extends StateNotifier<AsyncValue<List<MusicListening>>> {
  final MusicListeningRepository _repository;

  MusicListeningNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadListening();
  }

  Future<void> loadListening() async {
    state = const AsyncValue.loading();
    try {
      final listening = await _repository.getAllMusicListening();
      state = AsyncValue.data(listening);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMusicListening(MusicListening listening) async {
    try {
      await _repository.insertMusicListening(listening);
      await loadListening();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMusicListening(int id) async {
    try {
      await _repository.deleteMusicListening(id);
      await loadListening();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> searchMusic(String query) async {
    state = const AsyncValue.loading();
    try {
      final results = await _repository.searchMusic(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}