import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/activity_heatmap/domain/activity_heatmap.dart';
import 'package:thing_note/core/database/database_provider.dart';

final activityHeatmapRepositoryProvider = Provider((ref) => ActivityHeatmapRepository(ref));

class ActivityHeatmapRepository {
  final Ref _ref;

  ActivityHeatmapRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  /// Update heatmap data from records
  Future<void> updateHeatmapFromRecords() async {
    final db = await _db;
    
    // Get all records and aggregate by date/hour
    final records = await db.query('episode_records', columns: ['occurred_at', 'duration_sec']);
    
    final Map<String, Map<String, int>> aggregated = {}; // date -> hour -> count
    
    for (final record in records) {
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      final dateKey = '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';
      final hour = occurredAt.hour;
      
      aggregated.putIfAbsent(dateKey, () => {});
      aggregated[dateKey]![hour.toString()] = (aggregated[dateKey]![hour.toString()] ?? 0) + 1;
    }
    
    // Batch insert/update
    final batch = db.batch();
    for (final dateEntry in aggregated.entries) {
      final parts = dateEntry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      for (final hourEntry in dateEntry.value.entries) {
        final hour = int.parse(hourEntry.key);
        final count = hourEntry.value;
        
        batch.insert(
          'activity_heatmap',
          {
            'year': year,
            'month': month,
            'day': day,
            'hour': hour,
            'record_count': count,
            'total_duration_minutes': 0,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<ActivityDataPoint>> getDailyHeatmap(int year, int month, int day) async {
    final db = await _db;
    final results = await db.query(
      'activity_heatmap',
      where: 'year = ? AND month = ? AND day = ?',
      whereArgs: [year, month, day],
    );
    return results.map((e) => ActivityDataPoint.fromMap(e)).toList();
  }

  Future<List<ActivityDataPoint>> getMonthlyHeatmap(int year, int month) async {
    final db = await _db;
    final results = await db.query(
      'activity_heatmap',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'day ASC, hour ASC',
    );
    return results.map((e) => ActivityDataPoint.fromMap(e)).toList();
  }

  Future<MonthlyHeatmap> getMonthlyHeatmapGrid(int year, int month) async {
    final points = await getMonthlyHeatmap(year, month);
    final Map<int, Map<int, ActivityDataPoint>> grid = {};
    
    for (final point in points) {
      grid.putIfAbsent(point.day, () => {});
      grid[point.day]![point.hour] = point;
    }
    
    return MonthlyHeatmap(year: year, month: month, grid: grid);
  }

  Future<Map<int, int>> getDayActivityCounts(int year, int month) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT day, SUM(record_count) as total
      FROM activity_heatmap
      WHERE year = ? AND month = ?
      GROUP BY day
    ''', [year, month]);
    
    return Map.fromEntries(
      results.map((e) => MapEntry(e['day'] as int, e['total'] as int)),
    );
  }

  Future<List<Map<String, dynamic>>> getHourlyDistribution(int year, int month) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT hour, SUM(record_count) as total, AVG(total_duration_minutes) as avg_duration
      FROM activity_heatmap
      WHERE year = ? AND month = ?
      GROUP BY hour
      ORDER BY hour
    ''', [year, month]);
  }

  Future<Map<String, int>> getWeeklyDistribution(int year, int month) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT day, SUM(record_count) as total
      FROM activity_heatmap
      WHERE year = ? AND month = ?
      GROUP BY day
    ''', [year, month]);
    
    // Map day numbers to weekday names
    final Map<String, int> weekData = {
      '周一': 0, '周二': 0, '周三': 0, '周四': 0, '周五': 0, '周六': 0, '周日': 0,
    };
    
    for (final r in results) {
      final day = r['day'] as int;
      final total = r['total'] as int;
      final date = DateTime(year, month, day);
      final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekdayName = weekdayNames[date.weekday - 1];
      weekData[weekdayName] = (weekData[weekdayName] ?? 0) + total;
    }
    
    return weekData;
  }

  Future<Map<String, dynamic>> getActivityStats(int year, int month) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT 
        SUM(record_count) as total_records,
        SUM(total_duration_minutes) as total_minutes,
        AVG(record_count) as avg_daily,
        MAX(record_count) as max_daily
      FROM activity_heatmap
      WHERE year = ? AND month = ?
    ''', [year, month]);
    
    if (results.isEmpty) {
      return {
        'totalRecords': 0,
        'totalMinutes': 0,
        'avgDaily': 0.0,
        'maxDaily': 0,
      };
    }
    
    final r = results.first;
    return {
      'totalRecords': r['total_records'] as int? ?? 0,
      'totalMinutes': r['total_minutes'] as int? ?? 0,
      'avgDaily': (r['avg_daily'] as num?)?.toDouble() ?? 0.0,
      'maxDaily': r['max_daily'] as int? ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getYearlyOverview(int year) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT month, SUM(record_count) as total
      FROM activity_heatmap
      WHERE year = ?
      GROUP BY month
      ORDER BY month
    ''', [year]);
  }
}