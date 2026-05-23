import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood/domain/mood_entry.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodRepository(dbAsync);
});

final moodEntriesProvider = StateNotifierProvider<MoodEntriesNotifier, AsyncValue<List<MoodEntry>>>((ref) {
  final repository = ref.watch(moodRepositoryProvider);
  return MoodEntriesNotifier(repository);
});

final todayMoodProvider = Provider<MoodEntry?>((ref) {
  final moods = ref.watch(moodEntriesProvider);
  return moods.whenOrNull(
    data: (list) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      try {
        return list.firstWhere(
          (m) => m.timestamp.isAfter(todayStart),
        );
      } catch (_) {
        return null;
      }
    },
  );
});

class MoodRepository {
  final AsyncValue<Database> _dbAsync;

  MoodRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMood(MoodEntry mood) async {
    final db = await _db;
    return db.insert('mood_entries', mood.toMap());
  }

  Future<int> updateMood(MoodEntry mood) async {
    final db = await _db;
    return db.update(
      'mood_entries',
      mood.toMap(),
      where: 'id = ?',
      whereArgs: [mood.id],
    );
  }

  Future<int> deleteMood(int id) async {
    final db = await _db;
    return db.delete('mood_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MoodEntry>> getAllMoods() async {
    final db = await _db;
    final maps = await db.query('mood_entries', orderBy: 'timestamp DESC');
    return maps.map((m) => MoodEntry.fromMap(m)).toList();
  }

  Future<List<MoodEntry>> getMoodsByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'mood_entries',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => MoodEntry.fromMap(m)).toList();
  }

  Future<MoodEntry?> getMoodForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final moods = await getMoodsByDateRange(start, end);
    return moods.isNotEmpty ? moods.first : null;
  }

  Future<Map<MoodLevel, int>> getMoodDistribution(DateTime start, DateTime end) async {
    final moods = await getMoodsByDateRange(start, end);
    final dist = <MoodLevel, int>{};
    for (final mood in moods) {
      dist[mood.mood] = (dist[mood.mood] ?? 0) + 1;
    }
    return dist;
  }

  Future<double> getAverageMood(DateTime start, DateTime end) async {
    final moods = await getMoodsByDateRange(start, end);
    if (moods.isEmpty) return 0;
    final sum = moods.fold(0, (s, m) => s + m.mood.value);
    return sum / moods.length;
  }
}

class MoodEntriesNotifier extends StateNotifier<AsyncValue<List<MoodEntry>>> {
  final MoodRepository _repository;

  MoodEntriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMoods();
  }

  Future<void> loadMoods() async {
    state = const AsyncValue.loading();
    try {
      final moods = await _repository.getAllMoods();
      state = AsyncValue.data(moods);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMood(MoodEntry mood) async {
    try {
      await _repository.insertMood(mood);
      await loadMoods();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMood(MoodEntry mood) async {
    try {
      await _repository.updateMood(mood);
      await loadMoods();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMood(int id) async {
    try {
      await _repository.deleteMood(id);
      await loadMoods();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}