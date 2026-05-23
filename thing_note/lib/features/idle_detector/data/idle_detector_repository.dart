import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/idle_time_record.dart';

/// Provider for the idle detector repository
final idleDetectorRepositoryProvider = Provider<IdleDetectorRepository>((ref) {
  final db = ref.watch(databaseProvider).value;
  return IdleDetectorRepository(db);
});

/// Repository for managing idle time records
class IdleDetectorRepository {
  final Database? _db;

  IdleDetectorRepository(this._db);

  Database get _database {
    if (_db == null) {
      throw Exception('Database not initialized');
    }
    return _db!;
  }

  /// Insert a new idle time record
  Future<int> insert(IdleTimeRecord record) async {
    return await _database.insert('idle_time_records', record.toMap());
  }

  /// Update an existing idle time record
  Future<int> update(IdleTimeRecord record) async {
    return await _database.update(
      'idle_time_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Delete an idle time record
  Future<int> delete(int id) async {
    return await _database.delete(
      'idle_time_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all idle time records
  Future<List<IdleTimeRecord>> getAllRecords({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final maps = await _database.query(
      'idle_time_records',
      orderBy: orderBy ?? 'started_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => IdleTimeRecord.fromMap(m)).toList();
  }

  /// Get records for a specific date range
  Future<List<IdleTimeRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final maps = await _database.query(
      'idle_time_records',
      where: 'started_at >= ? AND started_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => IdleTimeRecord.fromMap(m)).toList();
  }

  /// Get records by idle type
  Future<List<IdleTimeRecord>> getRecordsByType(IdleType type) async {
    final maps = await _database.query(
      'idle_time_records',
      where: 'idle_type = ?',
      whereArgs: [type.toDbString()],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => IdleTimeRecord.fromMap(m)).toList();
  }

  /// Get productive records
  Future<List<IdleTimeRecord>> getProductiveRecords() async {
    final maps = await _database.query(
      'idle_time_records',
      where: 'is_productive = 1',
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => IdleTimeRecord.fromMap(m)).toList();
  }

  /// Get a single record by ID
  Future<IdleTimeRecord?> getRecordById(int id) async {
    final maps = await _database.query(
      'idle_time_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IdleTimeRecord.fromMap(maps.first);
  }

  /// Get statistics for a date range
  Future<IdleTimeStats> getStats({DateTime? startDate, DateTime? endDate}) async {
    final records = await getRecordsByDateRange(
      startDate ?? DateTime(2000),
      endDate ?? DateTime.now(),
    );

    return IdleTimeStats.fromRecords(records);
  }

  /// Get today's records
  Future<List<IdleTimeRecord>> getTodayRecords() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getRecordsByDateRange(startOfDay, endOfDay);
  }

  /// Get this week's records
  Future<List<IdleTimeRecord>> getThisWeekRecords() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return getRecordsByDateRange(start, end);
  }

  /// Get this month's records
  Future<List<IdleTimeRecord>> getThisMonthRecords() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return getRecordsByDateRange(start, end);
  }

  /// Get aggregated stats by type
  Future<Map<IdleType, Map<String, dynamic>>> getStatsByType() async {
    final results = await _database.rawQuery('''
      SELECT 
        idle_type,
        COUNT(*) as count,
        SUM(duration_minutes) as total_minutes,
        AVG(duration_minutes) as avg_minutes,
        SUM(CASE WHEN is_productive = 1 THEN 1 ELSE 0 END) as productive_count
      FROM idle_time_records
      GROUP BY idle_type
    ''');

    final stats = <IdleType, Map<String, dynamic>>{};
    for (final row in results) {
      final type = IdleType.fromString(row['idle_type'] as String);
      stats[type] = {
        'count': row['count'] as int,
        'total_minutes': row['total_minutes'] as int? ?? 0,
        'avg_minutes': (row['avg_minutes'] as num?)?.toDouble() ?? 0,
        'productive_count': row['productive_count'] as int? ?? 0,
      };
    }
    return stats;
  }

  /// Get daily summary for the last N days
  Future<List<Map<String, dynamic>>> getDailySummary({int days = 7}) async {
    final results = await _database.rawQuery('''
      SELECT 
        DATE(started_at) as date,
        COUNT(*) as record_count,
        SUM(duration_minutes) as total_minutes,
        AVG(duration_minutes) as avg_minutes,
        SUM(CASE WHEN is_productive = 1 THEN 1 ELSE 0 END) as productive_count
      FROM idle_time_records
      WHERE started_at >= DATE('now', '-$days days')
      GROUP BY DATE(started_at)
      ORDER BY date DESC
    ''');
    return results;
  }
}