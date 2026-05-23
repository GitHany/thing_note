import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/stress_models.dart';

final stressRepositoryProvider = Provider<StressRepository>((ref) {
  return StressRepository(ref.watch(databaseProvider).value!);
});

class StressRepository {
  final Database _db;

  StressRepository(this._db);

  Future<int> insert(StressIndicator indicator) async {
    return await _db.insert('stress_indicators', indicator.toMap());
  }

  Future<int> update(StressIndicator indicator) async {
    return await _db.update(
      'stress_indicators',
      indicator.toMap(),
      where: 'id = ?',
      whereArgs: [indicator.id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      'stress_indicators',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StressIndicator>> getAll() async {
    final maps = await _db.query('stress_indicators', orderBy: 'recorded_at DESC');
    return maps.map((m) => StressIndicator.fromMap(m)).toList();
  }

  Future<StressIndicator?> getById(int id) async {
    final maps = await _db.query(
      'stress_indicators',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? StressIndicator.fromMap(maps.first) : null;
  }

  Future<List<StressIndicator>> getByDateRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'stress_indicators',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => StressIndicator.fromMap(m)).toList();
  }

  Future<List<StressIndicator>> getByTriggerType(String triggerType) async {
    final maps = await _db.query(
      'stress_indicators',
      where: 'trigger_type = ?',
      whereArgs: [triggerType],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => StressIndicator.fromMap(m)).toList();
  }

  Future<List<StressIndicator>> getRecent({int limit = 20}) async {
    final maps = await _db.query(
      'stress_indicators',
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
    return maps.map((m) => StressIndicator.fromMap(m)).toList();
  }

  /// Get comprehensive stress statistics
  Future<Map<String, dynamic>> getStressStats({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final result = await _db.rawQuery('''
      SELECT 
        AVG(stress_level) as avg_stress,
        MAX(stress_level) as max_stress,
        MIN(stress_level) as min_stress,
        COUNT(*) as total_entries,
        AVG(mood_score) as avg_mood,
        AVG(energy_level) as avg_energy,
        AVG(effectiveness_rating) as avg_effectiveness
      FROM stress_indicators
      WHERE recorded_at >= ?
    ''', [startDate.toIso8601String()]);

    // Get trigger type distribution
    final triggerStats = await _db.rawQuery('''
      SELECT trigger_type, COUNT(*) as count
      FROM stress_indicators
      WHERE recorded_at >= ? AND trigger_type IS NOT NULL
      GROUP BY trigger_type
      ORDER BY count DESC
    ''', [startDate.toIso8601String()]);

    // Get daily average for trend
    final dailyStats = await _db.rawQuery('''
      SELECT 
        date(recorded_at) as day,
        AVG(stress_level) as avg_stress
      FROM stress_indicators
      WHERE recorded_at >= ?
      GROUP BY date(recorded_at)
      ORDER BY day DESC
      LIMIT ?
    ''', [startDate.toIso8601String(), days]);

    return {
      ...result.first,
      'trigger_distribution': triggerStats,
      'daily_trend': dailyStats,
    };
  }

  /// Get stress patterns with analysis
  Future<List<StressPattern>> getPatterns({int minOccurrences = 2}) async {
    // Get trigger type patterns
    final results = await _db.rawQuery('''
      SELECT 
        trigger_type,
        AVG(stress_level) as avg_stress,
        COUNT(*) as frequency,
        AVG(effectiveness_rating) as success_rate
      FROM stress_indicators
      WHERE trigger_type IS NOT NULL
      GROUP BY trigger_type
      HAVING COUNT(*) >= ?
      ORDER BY frequency DESC
    ''', [minOccurrences]);

    // Get common symptoms and strategies for each trigger type
    final patterns = <StressPattern>[];
    for (final r in results) {
      final trigger = r['trigger_type'] as String;
      final avgStress = (r['avg_stress'] as num?)?.toDouble() ?? 0;
      final frequency = r['frequency'] as int;
      final successRate = (r['success_rate'] as num?)?.toDouble() ?? 0;

      patterns.add(StressPattern(
        triggerType: trigger,
        avgStressLevel: avgStress,
        frequency: frequency,
        successRate: successRate,
        recommendation: _generateRecommendation(trigger, avgStress, successRate),
      ));
    }

    return patterns;
  }

  String _generateRecommendation(String triggerType, double avgStress, double successRate) {
    final recommendations = {
      StressTriggerType.work: [
        '考虑与上司沟通工作负荷',
        '使用时间管理工具规划任务',
        '设置明确的工作与休息边界',
      ],
      StressTriggerType.personal: [
        '保证充足的休息和睡眠',
        '培养兴趣爱好转移注意力',
        '定期与朋友家人交流',
      ],
      StressTriggerType.health: [
        '建议咨询医疗专业人士',
        '保持规律的运动习惯',
        '注意饮食营养均衡',
      ],
      StressTriggerType.relationships: [
        '坦诚沟通表达感受',
        '学习有效的沟通技巧',
        '必要时寻求咨询帮助',
      ],
      StressTriggerType.financial: [
        '制定详细的预算计划',
        '区分必要支出和可选支出',
        '考虑寻求财务咨询',
      ],
      StressTriggerType.other: [
        '记录压力触发因素',
        '练习放松技巧',
        '保持健康的生活方式',
      ],
    };

    final specificRecs = recommendations[triggerType] ?? recommendations[StressTriggerType.other]!;
    
    if (avgStress >= 7) {
      return '⚠️ ${specificRecs[0]}';
    } else if (avgStress >= 5) {
      return '📌 ${specificRecs[1]}';
    }
    return '💡 ${specificRecs[2]}';
  }

  /// Get weekly stress trend
  Future<Map<String, double>> getWeeklyTrend() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final results = await _db.rawQuery('''
      SELECT 
        date(recorded_at) as day,
        AVG(stress_level) as avg_stress
      FROM stress_indicators
      WHERE recorded_at >= ?
      GROUP BY date(recorded_at)
      ORDER BY day ASC
    ''', [weekAgo.toIso8601String()]);

    return {
      for (final r in results)
        r['day'] as String: (r['avg_stress'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Get coping strategy effectiveness
  Future<Map<String, double>> getStrategyEffectiveness() async {
    final results = await _db.rawQuery('''
      SELECT coping_strategies, effectiveness_rating
      FROM stress_indicators
      WHERE coping_strategies IS NOT NULL 
        AND coping_strategies != ''
        AND effectiveness_rating IS NOT NULL
    ''');

    final strategyScores = <String, List<int>>{};
    for (final r in results) {
      final strategies = (r['coping_strategies'] as String?)?.split(',') ?? [];
      final effectiveness = r['effectiveness_rating'] as int? ?? 0;
      for (final strategy in strategies) {
        if (strategy.isNotEmpty) {
          strategyScores.putIfAbsent(strategy, () => []);
          strategyScores[strategy]!.add(effectiveness);
        }
      }
    }

    return strategyScores.map(
      (strategy, scores) => MapEntry(
        strategy, 
        scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0,
      ),
    );
  }

  /// Get today's stress entry if exists
  Future<StressIndicator?> getTodayEntry() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await _db.query(
      'stress_indicators',
      where: 'recorded_at >= ? AND recorded_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    return maps.isNotEmpty ? StressIndicator.fromMap(maps.first) : null;
  }

  /// Search stress entries by note content
  Future<List<StressIndicator>> searchByNote(String query) async {
    final maps = await _db.query(
      'stress_indicators',
      where: 'note LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => StressIndicator.fromMap(m)).toList();
  }

  /// Update effectiveness rating for an entry
  Future<void> updateEffectiveness(int id, int rating) async {
    await _db.update(
      'stress_indicators',
      {'effectiveness_rating': rating},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get today's average stress level
  Future<double?> getTodayAverageStress() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await _db.rawQuery('''
      SELECT AVG(stress_level) as avg FROM stress_indicators
      WHERE recorded_at >= ? AND recorded_at < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return (result.first['avg'] as num?)?.toDouble();
  }
}
