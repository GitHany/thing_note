import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mood_activity_correlation/domain/mood_activity_models.dart';

/// 情绪活动关联服务 Provider
final moodActivityServiceProvider = Provider<MoodActivityService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodActivityService(dbAsync);
});

/// 关联分析结果 Provider
final correlationResultsProvider = FutureProvider<List<MoodActivityCorrelation>>((ref) async {
  final service = ref.watch(moodActivityServiceProvider);
  return service.getAllCorrelations();
});

/// 活动洞察 Provider
final activityInsightsProvider = FutureProvider<List<ActivityInsight>>((ref) async {
  final service = ref.watch(moodActivityServiceProvider);
  return service.getInsights();
});

/// 矩阵数据 Provider
final moodMatrixProvider = FutureProvider<MoodActivityMatrix?>((ref) async {
  final service = ref.watch(moodActivityServiceProvider);
  return service.getCorrelationMatrix();
});

class MoodActivityService {
  final AsyncValue<Database> _dbAsync;

  MoodActivityService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 计算所有活动的情绪关联
  Future<void> calculateCorrelations() async {
    final db = await _db;
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90));

    // 获取所有活动及其情绪数据
    final result = await db.rawQuery('''
      SELECT 
        tn.name as activity_name,
        AVG(m.mood_level) as avg_mood,
        COUNT(*) as sample_count
      FROM episode_records r
      INNER JOIN thing_names tn ON r.thing_name_id = tn.id
      INNER JOIN mood_journals m ON DATE(r.occurred_at) = m.date
      WHERE r.occurred_at >= ? AND m.mood_level IS NOT NULL
      GROUP BY tn.name
      ORDER BY sample_count DESC
    ''', [startDate.toIso8601String()]);

    // 计算相关性强度（基于样本数和情绪评分）
    for (final row in result) {
      final activityName = row['activity_name'] as String;
      final avgMood = (row['avg_mood'] as num?)?.toDouble() ?? 0.0;
      final sampleCount = row['sample_count'] as int? ?? 0;

      // 计算相关性强度：基于情绪评分与平均值的偏差
      const baselineMood = 3.0;
      final correlationStrength = ((avgMood - baselineMood) / baselineMood).abs() * 100;

      // 更新或插入关联数据
      final existing = await db.query(
        'mood_activity_correlations',
        where: 'activity_name = ?',
        whereArgs: [activityName],
      );

      if (existing.isEmpty) {
        await db.insert('mood_activity_correlations', {
          'activity_name': activityName,
          'avg_mood_score': avgMood,
          'sample_count': sampleCount,
          'correlation_strength': correlationStrength,
          'last_calculated': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await db.update(
          'mood_activity_correlations',
          {
            'avg_mood_score': avgMood,
            'sample_count': sampleCount,
            'correlation_strength': correlationStrength,
            'last_calculated': DateTime.now().toIso8601String(),
          },
          where: 'activity_name = ?',
          whereArgs: [activityName],
        );
      }
    }
  }

  /// 获取所有关联数据
  Future<List<MoodActivityCorrelation>> getAllCorrelations() async {
    final db = await _db;
    final maps = await db.query(
      'mood_activity_correlations',
      orderBy: 'correlation_strength DESC, sample_count DESC',
    );
    return maps.map((m) => MoodActivityCorrelation.fromMap(m)).toList();
  }

  /// 获取高情绪活动（正面触发因素）
  Future<List<MoodActivityCorrelation>> getPositiveTriggers() async {
    final db = await _db;
    final maps = await db.query(
      'mood_activity_correlations',
      where: 'avg_mood_score > ? AND sample_count >= ?',
      whereArgs: [3.5, 3],
      orderBy: 'avg_mood_score DESC',
    );
    return maps.map((m) => MoodActivityCorrelation.fromMap(m)).toList();
  }

  /// 获取低情绪活动（负面触发因素）
  Future<List<MoodActivityCorrelation>> getNegativeTriggers() async {
    final db = await _db;
    final maps = await db.query(
      'mood_activity_correlations',
      where: 'avg_mood_score < ? AND sample_count >= ?',
      whereArgs: [2.5, 3],
      orderBy: 'avg_mood_score ASC',
    );
    return maps.map((m) => MoodActivityCorrelation.fromMap(m)).toList();
  }

  /// 获取关联矩阵数据
  Future<MoodActivityMatrix?> getCorrelationMatrix() async {
    final db = await _db;
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90));

    // 获取所有活动
    final activities = await db.rawQuery('''
      SELECT DISTINCT tn.name
      FROM episode_records r
      INNER JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE r.occurred_at >= ?
      ORDER BY tn.name
    ''', [startDate.toIso8601String()]);

    if (activities.isEmpty) return null;

    final activityNames = activities.map((a) => a['name'] as String).toList();
    final energyLevels = [1, 2, 3, 4, 5];

    // 构建矩阵
    final matrix = <List<double>>[];
    for (final activity in activityNames) {
      final row = <double>[];
      for (final energy in energyLevels) {
        final result = await db.rawQuery('''
          SELECT AVG(m.mood_level) as avg_mood
          FROM episode_records r
          INNER JOIN thing_names tn ON r.thing_name_id = tn.id
          INNER JOIN mood_journals m ON DATE(r.occurred_at) = m.date
          WHERE tn.name = ? AND m.mood_level = ?
        ''', [activity, energy]);

        final avgMood = (result.first['avg_mood'] as num?)?.toDouble() ?? 0.0;
        row.add(avgMood);
      }
      matrix.add(row);
    }

    return MoodActivityMatrix(
      activities: activityNames,
      energyLevels: energyLevels,
      correlationMatrix: matrix,
    );
  }

  /// 生成活动洞察
  Future<List<ActivityInsight>> getInsights() async {
    final db = await _db;
    final insights = <ActivityInsight>[];

    // 获取正面触发因素洞察
    final positiveTriggers = await getPositiveTriggers();
    for (final trigger in positiveTriggers.take(3)) {
      insights.add(ActivityInsight(
        insightType: 'positive_trigger',
        title: '💡 ${trigger.activityName} 让你心情更好',
        description: '这个活动平均让你情绪达到 ${trigger.avgMoodScore.toStringAsFixed(1)}/5，基于 ${trigger.sampleCount} 次记录。',
        confidenceScore: (trigger.sampleCount / 30).clamp(0.5, 1.0),
        generatedAt: DateTime.now(),
      ));
    }

    // 获取负面触发因素洞察
    final negativeTriggers = await getNegativeTriggers();
    for (final trigger in negativeTriggers.take(2)) {
      insights.add(ActivityInsight(
        insightType: 'negative_trigger',
        title: '⚠️ ${trigger.activityName} 可能影响情绪',
        description: '这个活动平均情绪为 ${trigger.avgMoodScore.toStringAsFixed(1)}/5，建议注意或调整。',
        confidenceScore: (trigger.sampleCount / 30).clamp(0.5, 1.0),
        generatedAt: DateTime.now(),
      ));
    }

    // 推荐活动
    if (positiveTriggers.isNotEmpty) {
      final topActivity = positiveTriggers.first;
      insights.add(ActivityInsight(
        insightType: 'recommendation',
        title: '🎯 建议增加 ${topActivity.activityName}',
        description: '这是一个高情绪活动，建议在日程中更多安排。',
        confidenceScore: 0.8,
        generatedAt: DateTime.now(),
      ));
    }

    // 保存洞察到数据库
    for (final insight in insights) {
      await db.insert('activity_insights', insight.toMap()..remove('id'));
    }

    return insights;
  }

  /// 获取周度关联趋势
  Future<List<WeeklyCorrelationTrend>> getWeeklyTrends({int weeks = 8}) async {
    final trends = <WeeklyCorrelationTrend>[];
    final now = DateTime.now();

    for (int i = 0; i < weeks; i++) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));

      final db = await _db;
      final result = await db.rawQuery('''
        SELECT 
          AVG(correlation_strength) as avg_correlation,
          SUM(sample_count) as total_samples
        FROM mood_activity_correlations
        WHERE last_calculated BETWEEN ? AND ?
      ''', [weekStart.toIso8601String(), weekEnd.toIso8601String()]);

      final avgCorrelation = (result.first['avg_correlation'] as num?)?.toDouble() ?? 0.0;
      final totalSamples = result.first['total_samples'] as int? ?? 0;

      trends.add(WeeklyCorrelationTrend(
        weekStart: weekStart,
        avgCorrelation: avgCorrelation,
        totalSamples: totalSamples,
        topPositiveActivities: [],
        topNegativeActivities: [],
      ));
    }

    return trends.reversed.toList();
  }
}