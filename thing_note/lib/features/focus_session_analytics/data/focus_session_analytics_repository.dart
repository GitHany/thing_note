import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/focus_session_analytics/domain/focus_session_analysis.dart';

final focusSessionAnalyticsProvider = Provider<FocusSessionAnalyticsRepository>((ref) {
  return FocusSessionAnalyticsRepository(ref.watch(databaseProvider.future));
});

class FocusSessionAnalyticsRepository {
  final Future<Database> _dbFuture;

  FocusSessionAnalyticsRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<FocusSessionAnalysis>> getAllAnalyses() async {
    final db = await _db;
    final results = await db.query('focus_session_analytics', orderBy: 'created_at DESC');
    return results.map((e) => FocusSessionAnalysis.fromMap(e)).toList();
  }

  Future<List<FocusSessionAnalysis>> getAnalysesForSession(int sessionId) async {
    final db = await _db;
    final results = await db.query(
      'focus_session_analytics',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => FocusSessionAnalysis.fromMap(e)).toList();
  }

  Future<int> insertAnalysis(FocusSessionAnalysis analysis) async {
    final db = await _db;
    return await db.insert('focus_session_analytics', analysis.toMap()..remove('id'));
  }

  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final db = await _db;

    final totalSessions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM focus_sessions'),
    ) ?? 0;

    final avgEfficiency = (await db.rawQuery('''
      SELECT AVG(efficiency_score) as avg_efficiency
      FROM focus_session_analytics
    ''')).first['avg_efficiency'] as double? ?? 0;

    final bestPeriod = await db.rawQuery('''
      SELECT best_focus_period, COUNT(*) as count
      FROM focus_session_analytics
      WHERE best_focus_period IS NOT NULL
      GROUP BY best_focus_period
      ORDER BY count DESC
      LIMIT 1
    ''');

    final commonDistraction = await db.rawQuery('''
      SELECT distraction_pattern, COUNT(*) as count
      FROM focus_session_analytics
      WHERE distraction_pattern IS NOT NULL
      GROUP BY distraction_pattern
      ORDER BY count DESC
      LIMIT 1
    ''');

    return {
      'total_sessions': totalSessions,
      'avg_efficiency': avgEfficiency,
      'best_period': bestPeriod.isNotEmpty ? bestPeriod.first['best_focus_period'] : null,
      'common_distraction': commonDistraction.isNotEmpty ? commonDistraction.first['distraction_pattern'] : null,
    };
  }

  Future<List<Map<String, dynamic>>> getEfficiencyTrend({int days = 30}) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));

    return await db.rawQuery('''
      SELECT DATE(created_at) as date, AVG(efficiency_score) as avg_efficiency
      FROM focus_session_analytics
      WHERE created_at >= ?
      GROUP BY DATE(created_at)
      ORDER BY date
    ''', [startDate.toIso8601String()]);
  }

  Future<Map<String, int>> getDistractionBreakdown() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT distraction_pattern, COUNT(*) as count
      FROM focus_session_analytics
      WHERE distraction_pattern IS NOT NULL
      GROUP BY distraction_pattern
    ''');

    return {for (var r in results) r['distraction_pattern'] as String: r['count'] as int};
  }
}