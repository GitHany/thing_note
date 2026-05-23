import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/time_audit/domain/time_audit_model.dart';

/// Repository for Time Audit data operations
class TimeAuditRepository {
  final Database db;

  TimeAuditRepository(this.db);

  /// Create a time audit entry
  Future<int> createEntry(TimeAuditEntry entry) async {
    return await db.insert('time_audit_entries', entry.toMap());
  }

  /// Update a time audit entry
  Future<int> updateEntry(TimeAuditEntry entry) async {
    return await db.update(
      'time_audit_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete an entry
  Future<int> deleteEntry(int id) async {
    return await db.delete(
      'time_audit_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get entries by date range
  Future<List<TimeAuditEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'time_audit_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String().substring(0, 10), end.toIso8601String().substring(0, 10)],
      orderBy: 'start_hour ASC',
    );
    return maps.map((map) => TimeAuditEntry.fromMap(map)).toList();
  }

  /// Get weekly entries
  Future<List<TimeAuditEntry>> getWeeklyEntries() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return getEntriesByDateRange(start, now);
  }

  /// Get category distribution
  Future<List<TimeDistribution>> getCategoryDistribution(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await getEntriesByDateRange(start, end);
    if (entries.isEmpty) return [];

    // Group by category
    final categoryMinutes = <String, int>{};
    final categoryCounts = <String, int>{};
    
    for (final entry in entries) {
      categoryMinutes[entry.category] = 
          (categoryMinutes[entry.category] ?? 0) + entry.durationMinutes;
      categoryCounts[entry.category] = 
          (categoryCounts[entry.category] ?? 0) + 1;
    }

    final totalMinutes = categoryMinutes.values.fold(0, (sum, mins) => sum + mins);

    final distributions = <TimeDistribution>[];
    for (final category in categoryMinutes.keys) {
      distributions.add(TimeDistribution(
        category: category,
        totalMinutes: categoryMinutes[category]!,
        percentage: totalMinutes > 0 
            ? categoryMinutes[category]! / totalMinutes * 100 
            : 0,
        entryCount: categoryCounts[category]!,
      ));
    }

    distributions.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return distributions;
  }

  /// Get peak productivity hours
  Future<List<PeakProductivityHour>> getPeakProductivityHours({
    int? startHour,
    int? endHour,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startHour != null && endHour != null) {
      whereClause = 'start_hour >= ? AND start_hour < ?';
      whereArgs = [startHour, endHour];
    }

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        start_hour,
        AVG(productivity) as avg_productivity,
        COUNT(*) as session_count
      FROM time_audit_entries
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY start_hour
      ORDER BY avg_productivity DESC
    ''', whereArgs);

    return results.map((row) => PeakProductivityHour(
      hour: row['start_hour'] as int,
      avgProductivity: (row['avg_productivity'] as num?)?.toDouble() ?? 0,
      sessionCount: row['session_count'] as int,
    )).toList();
  }

  /// Get statistics
  Future<TimeAuditStats> getStats(DateTime start, DateTime end) async {
    final entries = await getEntriesByDateRange(start, end);
    
    if (entries.isEmpty) {
      return TimeAuditStats.empty();
    }

    // Calculate totals
    int totalMinutes = 0;
    int productiveMinutes = 0;
    int totalProductivity = 0;

    for (final entry in entries) {
      totalMinutes += entry.durationMinutes;
      totalProductivity += entry.productivity;
      if (entry.productivity >= 4) {
        productiveMinutes += entry.durationMinutes;
      }
    }

    // Get category distribution
    final categoryDistribution = await getCategoryDistribution(start, end);

    // Get peak hours
    final peakHours = await getPeakProductivityHours();

    // Find most and least productive times
    final sortedByProductivity = [...peakHours]..sort((a, b) => 
        b.avgProductivity.compareTo(a.avgProductivity));
    
    String mostProductive = '';
    String leastProductive = '';
    
    if (sortedByProductivity.isNotEmpty) {
      mostProductive = _formatHour(sortedByProductivity.first.hour);
      if (sortedByProductivity.length > 1) {
        leastProductive = _formatHour(sortedByProductivity.last.hour);
      }
    }

    return TimeAuditStats(
      totalMinutes: totalMinutes,
      totalEntries: entries.length,
      productiveMinutes: productiveMinutes,
      avgProductivity: entries.isNotEmpty ? totalProductivity / entries.length : 0,
      mostProductiveTime: mostProductive,
      leastProductiveTime: leastProductive,
      categoryDistribution: categoryDistribution,
      peakHours: peakHours.take(5).toList(),
    );
  }

  String _formatHour(int hour) {
    final h = hour % 24;
    final amPm = h >= 12 ? '下午' : '上午';
    final displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayHour $amPm';
  }
}