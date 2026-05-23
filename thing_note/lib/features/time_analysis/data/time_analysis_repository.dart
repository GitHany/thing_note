import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/time_analysis/domain/time_analysis_record.dart';

final timeAnalysisRepositoryProvider = Provider<TimeAnalysisRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return TimeAnalysisRepository(dbAsync);
});

class TimeAnalysisRepository {
  final AsyncValue<Database> _dbAsync;

  TimeAnalysisRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> analyzeDay(String date) async {
    final db = await _db;

    final morning = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE date(occurred_at) = ? AND CAST(strftime('%H', occurred_at) AS INTEGER) BETWEEN 6 AND 11
    ''', [date]);

    final afternoon = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE date(occurred_at) = ? AND CAST(strftime('%H', occurred_at) AS INTEGER) BETWEEN 12 AND 17
    ''', [date]);

    final evening = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE date(occurred_at) = ? AND CAST(strftime('%H', occurred_at) AS INTEGER) BETWEEN 18 AND 23
    ''', [date]);

    final night = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE date(occurred_at) = ? AND CAST(strftime('%H', occurred_at) AS INTEGER) BETWEEN 0 AND 5
    ''', [date]);

    final weekday = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE date(occurred_at) = ? AND CAST(strftime('%w', occurred_at) AS INTEGER) BETWEEN 1 AND 5
    ''', [date]);

    final weekend = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE date(occurred_at) = ? AND CAST(strftime('%w', occurred_at) AS INTEGER) IN (0, 6)
    ''', [date]);

    final avgDuration = await db.rawQuery('''
      SELECT AVG(duration_sec) as avg FROM episode_records
      WHERE date(occurred_at) = ? AND duration_sec > 0
    ''', [date]);

    final record = TimeAnalysisRecord(
      date: date,
      morningRecords: morning.first['count'] as int? ?? 0,
      afternoonRecords: afternoon.first['count'] as int? ?? 0,
      eveningRecords: evening.first['count'] as int? ?? 0,
      nightRecords: night.first['count'] as int? ?? 0,
      weekdayRecords: weekday.first['count'] as int? ?? 0,
      weekendRecords: weekend.first['count'] as int? ?? 0,
      averageDuration: (avgDuration.first['avg'] as num?)?.toDouble(),
    );

    await db.insert(
      'time_analysis_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TimeAnalysisRecord>> getRecent(int days) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_analysis_records',
      orderBy: 'date DESC',
      limit: days,
    );
    return maps.map((map) => TimeAnalysisRecord.fromMap(map)).toList();
  }

  Future<Map<String, int>> getTimeDistribution(int days) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT
        SUM(morning_records) as morning,
        SUM(afternoon_records) as afternoon,
        SUM(evening_records) as evening,
        SUM(night_records) as night
      FROM time_analysis_records
      WHERE date >= datetime('now', '-$days days')
    ''');

    return {
      'morning': (result.first['morning'] as int?) ?? 0,
      'afternoon': (result.first['afternoon'] as int?) ?? 0,
      'evening': (result.first['evening'] as int?) ?? 0,
      'night': (result.first['night'] as int?) ?? 0,
    };
  }
}
