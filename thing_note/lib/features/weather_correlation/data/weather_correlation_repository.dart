import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/weather_correlation.dart';

final weatherCorrelationRepositoryProvider = Provider<WeatherCorrelationRepository>((ref) {
  return WeatherCorrelationRepository(ref);
});

class WeatherCorrelationRepository {
  final Ref _ref;

  WeatherCorrelationRepository(this._ref);

  Future<Database> get _db async {
    final dbAsync = _ref.watch(databaseProvider);
    return dbAsync.value!;
  }

  /// 插入或更新天气关联记录
  Future<int> upsertRecord(WeatherCorrelation record) async {
    final db = await _db;
    // 检查当天是否已有记录
    final existing = await db.query(
      'weather_correlations',
      where: 'date = ?',
      whereArgs: [record.date],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // 更新现有记录
      return await db.update(
        'weather_correlations',
        record.toMap(),
        where: 'date = ?',
        whereArgs: [record.date],
      );
    } else {
      // 插入新记录
      return await db.insert('weather_correlations', record.toMap());
    }
  }

  /// 获取指定日期范围的记录
  Future<List<WeatherCorrelation>> getByDateRange(String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query(
      'weather_correlations',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((map) => WeatherCorrelation.fromMap(map)).toList();
  }

  /// 获取指定日期的记录
  Future<WeatherCorrelation?> getByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'weather_correlations',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return maps.isNotEmpty ? WeatherCorrelation.fromMap(maps.first) : null;
  }

  /// 获取所有记录
  Future<List<WeatherCorrelation>> getAllRecords() async {
    final db = await _db;
    final maps = await db.query(
      'weather_correlations',
      orderBy: 'date DESC',
    );
    return maps.map((map) => WeatherCorrelation.fromMap(map)).toList();
  }

  /// 获取最近的N条记录
  Future<List<WeatherCorrelation>> getRecentRecords(int limit) async {
    final db = await _db;
    final maps = await db.query(
      'weather_correlations',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => WeatherCorrelation.fromMap(map)).toList();
  }

  /// 按天气状况分组统计
  Future<List<WeatherStats>> getStatsByWeather() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        weather_condition,
        COUNT(*) as count,
        AVG(productivity_score) as avg_productivity,
        AVG(mood_score) as avg_mood,
        AVG(energy_level) as avg_energy,
        AVG(temperature) as avg_temperature
      FROM weather_correlations
      WHERE weather_condition IS NOT NULL
      GROUP BY weather_condition
      ORDER BY count DESC
    ''');

    return result.map((row) => WeatherStats(
      weatherCondition: row['weather_condition'] as String? ?? '未知',
      count: row['count'] as int? ?? 0,
      avgProductivity: (row['avg_productivity'] as num?)?.toDouble() ?? 0,
      avgMood: (row['avg_mood'] as num?)?.toDouble() ?? 0,
      avgEnergy: (row['avg_energy'] as num?)?.toDouble() ?? 0,
      avgTemperature: (row['avg_temperature'] as num?)?.toDouble() ?? 0,
    )).toList();
  }

  /// 按温度范围分组统计
  Future<List<TemperatureRangeStats>> getStatsByTemperature() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        CASE
          WHEN temperature < 0 THEN '极寒 (<0°C)'
          WHEN temperature < 10 THEN '寒冷 (0-10°C)'
          WHEN temperature < 20 THEN '凉爽 (10-20°C)'
          WHEN temperature < 25 THEN '舒适 (20-25°C)'
          WHEN temperature < 30 THEN '温暖 (25-30°C)'
          ELSE '炎热 (>30°C)'
        END as range_label,
        COUNT(*) as count,
        AVG(productivity_score) as avg_productivity,
        AVG(mood_score) as avg_mood,
        AVG(energy_level) as avg_energy
      FROM weather_correlations
      WHERE temperature IS NOT NULL
      GROUP BY range_label
      ORDER BY 
        CASE range_label
          WHEN '极寒 (<0°C)' THEN 1
          WHEN '寒冷 (0-10°C)' THEN 2
          WHEN '凉爽 (10-20°C)' THEN 3
          WHEN '舒适 (20-25°C)' THEN 4
          WHEN '温暖 (25-30°C)' THEN 5
          ELSE 6
        END
    ''');

    return result.map((row) => TemperatureRangeStats(
      rangeLabel: row['range_label'] as String? ?? '未知',
      count: row['count'] as int? ?? 0,
      avgProductivity: (row['avg_productivity'] as num?)?.toDouble() ?? 0,
      avgMood: (row['avg_mood'] as num?)?.toDouble() ?? 0,
      avgEnergy: (row['avg_energy'] as num?)?.toDouble() ?? 0,
    )).toList();
  }

  /// 获取平均生产力分数
  Future<double> getAverageProductivity(String startDate, String endDate) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT AVG(productivity_score) as avg FROM weather_correlations WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0;
  }

  /// 获取平均情绪分数
  Future<double> getAverageMood(String startDate, String endDate) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT AVG(mood_score) as avg FROM weather_correlations WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0;
  }

  /// 删除记录
  Future<int> deleteRecord(int id) async {
    final db = await _db;
    return await db.delete(
      'weather_correlations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取记录数量
  Future<int> getRecordCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM weather_correlations');
    return result.first['count'] as int? ?? 0;
  }

  /// 获取最佳天气条件（生产力最高）
  Future<String?> getBestWeatherCondition() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT weather_condition, AVG(productivity_score) as avg_score
      FROM weather_correlations
      WHERE weather_condition IS NOT NULL
      GROUP BY weather_condition
      ORDER BY avg_score DESC
      LIMIT 1
    ''');
    return result.isNotEmpty ? result.first['weather_condition'] as String? : null;
  }

  /// 获取最佳温度范围（生产力最高）
  Future<String?> getBestTemperatureRange() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        CASE
          WHEN temperature < 0 THEN '极寒 (<0°C)'
          WHEN temperature < 10 THEN '寒冷 (0-10°C)'
          WHEN temperature < 20 THEN '凉爽 (10-20°C)'
          WHEN temperature < 25 THEN '舒适 (20-25°C)'
          WHEN temperature < 30 THEN '温暖 (25-30°C)'
          ELSE '炎热 (>30°C)'
        END as range_label,
        AVG(productivity_score) as avg_score
      FROM weather_correlations
      WHERE temperature IS NOT NULL
      GROUP BY range_label
      ORDER BY avg_score DESC
      LIMIT 1
    ''');
    return result.isNotEmpty ? result.first['range_label'] as String? : null;
  }
}