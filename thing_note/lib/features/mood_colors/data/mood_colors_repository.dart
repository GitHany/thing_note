import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_colors/domain/mood_color.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final moodColorsRepositoryProvider = Provider<MoodColorsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodColorsRepository(dbAsync);
});

final moodColorsTodayProvider = FutureProvider<MoodColor?>((ref) async {
  final repo = ref.watch(moodColorsRepositoryProvider);
  return repo.getMoodColorByDate(_todayDate());
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class MoodColorsRepository {
  final AsyncValue<Database> _dbAsync;

  MoodColorsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMoodColor(MoodColor moodColor) async {
    final db = await _db;
    return db.insert('mood_colors', moodColor.toMap());
  }

  Future<int> updateMoodColor(MoodColor moodColor) async {
    final db = await _db;
    return db.update('mood_colors', moodColor.toMap(), where: 'id = ?', whereArgs: [moodColor.id]);
  }

  Future<MoodColor?> getMoodColorByDate(String date) async {
    final db = await _db;
    final maps = await db.query('mood_colors', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return MoodColor.fromMap(maps.first);
  }

  Future<int> upsertMoodColor(String date, String colorHex, int moodLevel, String? emotion, double intensity) async {
    final db = await _db;
    final existing = await getMoodColorByDate(date);
    if (existing != null) {
      return db.update(
        'mood_colors',
        {'color_hex': colorHex, 'mood_level': moodLevel, 'primary_emotion': emotion, 'intensity': intensity},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
    final now = DateTime.now();
    return db.insert('mood_colors', {
      'date': date,
      'color_hex': colorHex,
      'mood_level': moodLevel,
      'primary_emotion': emotion,
      'intensity': intensity,
      'created_at': now.toIso8601String(),
    });
  }

  Future<List<MoodColor>> getMoodColorsForMonth(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    final maps = await db.query(
      'mood_colors',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => MoodColor.fromMap(m)).toList();
  }

  Future<List<MoodColor>> getMoodColorsForYear(int year) async {
    final db = await _db;
    final startDate = '$year-01-01';
    final endDate = '$year-12-31';
    final maps = await db.query(
      'mood_colors',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => MoodColor.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getMoodColorStats(int year) async {
    final colors = await getMoodColorsForYear(year);
    if (colors.isEmpty) return {'count': 0, 'avg_mood': 0.0};

    final double avgMood = colors.fold(0.0, (sum, c) => sum + c.moodLevel) / colors.length;
    final Map<String, int> emotionDist = {};
    for (final c in colors) {
      final e = c.primaryEmotion ?? '未知';
      emotionDist[e] = (emotionDist[e] ?? 0) + 1;
    }
    return {
      'count': colors.length,
      'avg_mood': avgMood,
      'emotion_distribution': emotionDist,
    };
  }
}
