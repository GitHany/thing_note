import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mood_heatmap/domain/mood_heatmap_data.dart';

final moodHeatmapRepositoryProvider = Provider<MoodHeatmapRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodHeatmapRepository(dbAsync);
});

class MoodHeatmapRepository {
  final AsyncValue<Database> _dbAsync;

  MoodHeatmapRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> syncFromMoodEntries() async {
    final db = await _db;

    final entries = await db.query('mood_entries');

    for (final entry in entries) {
      final date = DateTime.parse(entry['date'] as String);
      final level = entry['level'] as int;

      double intensity = 1.0;
      final triggers = entry['triggers'] as String?;
      final activities = entry['activities'] as String?;

      if (triggers != null && triggers.isNotEmpty) {
        intensity += triggers.split(',').length * 0.1;
      }
      if (activities != null && activities.isNotEmpty) {
        intensity += activities.split(',').length * 0.1;
      }
      intensity = intensity.clamp(0.5, 2.0);

      final heatmapData = MoodHeatmapData(
        year: date.year,
        month: date.month,
        day: date.day,
        moodLevel: level,
        intensity: intensity,
      );

      await db.insert(
        'mood_heatmap_data',
        heatmapData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<MoodHeatmapData>> getByYear(int year) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_heatmap_data',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'month ASC, day ASC',
    );
    return maps.map((map) => MoodHeatmapData.fromMap(map)).toList();
  }

  Future<List<MoodHeatmapData>> getByMonth(int year, int month) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_heatmap_data',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'day ASC',
    );
    return maps.map((map) => MoodHeatmapData.fromMap(map)).toList();
  }

  Future<Map<String, double>> getMonthlyAverages(int year) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT month, AVG(mood_level) as avg_mood
      FROM mood_heatmap_data
      WHERE year = ?
      GROUP BY month
    ''', [year]);

    final Map<String, double> averages = {};
    for (final row in result) {
      final month = row['month'] as int;
      final avgMood = (row['avg_mood'] as num?)?.toDouble() ?? 3.0;
      averages[month.toString()] = avgMood;
    }
    return averages;
  }
}
