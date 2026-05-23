import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/daily_summary_widget/domain/daily_summary.dart';
import 'package:thing_note/core/database/database_provider.dart';

final dailySummaryRepositoryProvider = Provider((ref) => DailySummaryRepository(ref));

class DailySummaryRepository {
  final Ref _ref;

  DailySummaryRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<DailySummary?> getSummaryForDate(DateTime date) async {
    final db = await _db;
    final dateStr = _formatDate(date);
    final results = await db.query(
      'daily_summary_widget',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (results.isEmpty) return null;
    return DailySummary.fromMap(results.first);
  }

  Future<List<DailySummary>> getSummariesForRange(DateTime start, DateTime end) async {
    final db = await _db;
    final results = await db.query(
      'daily_summary_widget',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_formatDate(start), _formatDate(end)],
      orderBy: 'date DESC',
    );
    return results.map((e) => DailySummary.fromMap(e)).toList();
  }

  Future<void> saveSummary(DailySummary summary) async {
    final db = await _db;
    await db.insert(
      'daily_summary_widget',
      summary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSummary(DateTime date) async {
    final db = await _db;
    await db.delete(
      'daily_summary_widget',
      where: 'date = ?',
      whereArgs: [_formatDate(date)],
    );
  }

  /// Generate and save summary for a given date
  Future<DailySummary> generateSummaryForDate(DateTime date) async {
    final db = await _db;
    final dateStr = _formatDate(date);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Get record count and duration
    final recordStats = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(duration_sec) as total_sec
      FROM episode_records
      WHERE occurred_at >= ? AND occurred_at <= ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    // Get top thing name
    final topThing = await db.rawQuery('''
      SELECT tn.name, COUNT(*) as cnt
      FROM episode_records r
      JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE r.occurred_at >= ? AND r.occurred_at <= ?
      GROUP BY tn.name
      ORDER BY cnt DESC
      LIMIT 1
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    // Get completed goals count
    final goalsCompleted = await db.rawQuery('''
      SELECT COUNT(*) as count FROM goals
      WHERE DATE(COALESCE(updated_at, created_at)) = ?
      AND status = 'completed'
    ''', [dateStr]);

    final summary = DailySummary(
      date: date,
      recordCount: Sqflite.firstIntValue(recordStats) ?? 0,
      totalDurationMinutes: ((recordStats.first['total_sec'] as int?) ?? 0) ~/ 60,
      topThingName: topThing.isNotEmpty ? topThing.first['name'] as String? : null,
      completedGoals: Sqflite.firstIntValue(goalsCompleted) ?? 0,
      createdAt: DateTime.now(),
    );

    await saveSummary(summary);
    return summary;
  }

  Future<DailySummary> getOrGenerateSummary(DateTime date) async {
    final existing = await getSummaryForDate(date);
    if (existing != null) return existing;
    return await generateSummaryForDate(date);
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    final db = await _db;
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    final results = await db.rawQuery('''
      SELECT 
        SUM(record_count) as total_records,
        SUM(total_duration_minutes) as total_minutes,
        AVG(record_count) as avg_records,
        MAX(record_count) as max_records
      FROM daily_summary_widget
      WHERE date >= ? AND date <= ?
    ''', [_formatDate(weekStart), _formatDate(now)]);

    if (results.isEmpty) {
      return {
        'totalRecords': 0,
        'totalMinutes': 0,
        'avgRecords': 0.0,
        'maxRecords': 0,
      };
    }

    return {
      'totalRecords': results.first['total_records'] as int? ?? 0,
      'totalMinutes': results.first['total_minutes'] as int? ?? 0,
      'avgRecords': (results.first['avg_records'] as num?)?.toDouble() ?? 0.0,
      'maxRecords': results.first['max_records'] as int? ?? 0,
    };
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}