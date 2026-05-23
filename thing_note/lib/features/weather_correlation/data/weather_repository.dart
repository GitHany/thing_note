import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/weather_models.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(ref.watch(databaseProvider).value!);
});

class WeatherRepository {
  final Database _db;

  WeatherRepository(this._db);

  Future<int> insert(WeatherCorrelation data) async {
    return await _db.insert('weather_correlations', data.toMap());
  }

  Future<int> update(WeatherCorrelation data) async {
    return await _db.update(
      'weather_correlations',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<WeatherCorrelation?> getByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await _db.query(
      'weather_correlations',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return WeatherCorrelation.fromMap(maps.first);
  }

  Future<List<WeatherCorrelation>> getByRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'weather_correlations',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      ],
      orderBy: 'date DESC',
    );
    return maps.map((m) => WeatherCorrelation.fromMap(m)).toList();
  }

  Future<List<WeatherInsight>> getWeatherInsights() async {
    final results = await _db.rawQuery('''
      SELECT 
        weather_condition,
        AVG(productivity_score) as avg_productivity,
        AVG(mood_score) as avg_mood,
        COUNT(*) as sample_count
      FROM weather_correlations
      WHERE weather_condition IS NOT NULL
      GROUP BY weather_condition
      HAVING sample_count >= 3
      ORDER BY avg_productivity DESC
    ''');

    return results.map((r) {
      final condition = r['weather_condition'] as String;
      final productivity = (r['avg_productivity'] as num?)?.toDouble() ?? 0;
      return WeatherInsight(
        condition: condition,
        avgProductivity: productivity,
        sampleCount: r['sample_count'] as int,
        recommendation: _getRecommendation(condition, productivity),
      );
    }).toList();
  }

  String _getRecommendation(String condition, double productivity) {
    if (productivity >= 4) return 'Great day for focused work!';
    if (productivity >= 3) return 'Good day for routine tasks.';
    return 'Consider lighter tasks or breaks.';
  }

  Future<Map<String, dynamic>> getTemperatureCorrelation() async {
    final result = await _db.rawQuery('''
      SELECT 
        CASE
          WHEN temperature < 10 THEN 'cold'
          WHEN temperature BETWEEN 10 AND 20 THEN 'cool'
          WHEN temperature BETWEEN 20 AND 25 THEN 'comfortable'
          WHEN temperature BETWEEN 25 AND 30 THEN 'warm'
          ELSE 'hot'
        END as temp_range,
        AVG(productivity_score) as avg_productivity,
        COUNT(*) as sample_count
      FROM weather_correlations
      WHERE temperature IS NOT NULL
      GROUP BY temp_range
    ''');
    return result.first;
  }
}