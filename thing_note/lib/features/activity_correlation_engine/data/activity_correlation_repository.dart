import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/activity_correlation_engine/domain/activity_correlation.dart';

final activityCorrelationRepositoryProvider = Provider<ActivityCorrelationRepository>((ref) {
  return ActivityCorrelationRepository(ref.watch(databaseProvider.future));
});

class ActivityCorrelationRepository {
  final Future<Database> _dbFuture;

  ActivityCorrelationRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<ActivityCorrelation>> getAllCorrelations() async {
    final db = await _db;
    final results = await db.query('activity_correlations', orderBy: 'correlation_score DESC');
    return results.map((e) => ActivityCorrelation.fromMap(e)).toList();
  }

  Future<List<ActivityCorrelation>> getStrongCorrelations() async {
    final db = await _db;
    final results = await db.query(
      'activity_correlations',
      where: 'correlation_score > ? OR correlation_score < ?',
      whereArgs: [0.5, -0.5],
      orderBy: 'correlation_score DESC',
    );
    return results.map((e) => ActivityCorrelation.fromMap(e)).toList();
  }

  Future<int> insertCorrelation(ActivityCorrelation correlation) async {
    final db = await _db;
    return await db.insert('activity_correlations', correlation.toMap()..remove('id'));
  }

  Future<void> initializeDefaultCorrelations() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM activity_correlations')) ?? 0;

    if (count == 0) {
      final defaults = [
        ActivityCorrelation(activityName: '晨间运动', resultMetric: '日间精力', correlationScore: 0.75, sampleCount: 45, confidenceLevel: 0.85),
        ActivityCorrelation(activityName: '阅读30分钟', resultMetric: '睡眠质量', correlationScore: 0.62, sampleCount: 30, confidenceLevel: 0.72),
        ActivityCorrelation(activityName: '长时间工作', resultMetric: '情绪评分', correlationScore: -0.45, sampleCount: 50, confidenceLevel: 0.68),
      ];

      for (final correlation in defaults) {
        await db.insert('activity_correlations', correlation.toMap()..remove('id'));
      }
    }
  }
}