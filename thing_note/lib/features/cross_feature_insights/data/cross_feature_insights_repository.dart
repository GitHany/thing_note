import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/cross_feature_insights/domain/cross_feature_model.dart';

final crossFeatureInsightsRepositoryProvider = Provider<CrossFeatureInsightsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return CrossFeatureInsightsRepository(dbAsync);
});

class CrossFeatureInsightsRepository {
  final AsyncValue<Database> _dbAsync;

  CrossFeatureInsightsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<CrossFeatureInsight>> generateMoodProductivityInsights() async {
    final db = await _db;
    final insights = <CrossFeatureInsight>[];

    final moodRecords = await db.query('mood_journals', orderBy: 'date DESC', limit: 30);

    final productivityRecords = await db.query(
      'daily_productivity_scores',
      orderBy: 'date DESC',
      limit: 30,
    );

    if (moodRecords.isEmpty || productivityRecords.isEmpty) {
      return insights;
    }

    double totalCorrelation = 0;
    int matchCount = 0;

    final moodByDate = <String, int>{};
    for (final record in moodRecords) {
      final date = record['date'] as String;
      final mood = record['mood_level'] as int;
      moodByDate[date] = mood;
    }

    for (final record in productivityRecords) {
      final date = record['date'] as String;
      if (moodByDate.containsKey(date)) {
        final productivity = (record['overall_score'] as num?)?.toDouble() ?? 0;
        final mood = moodByDate[date]!;

        if ((mood >= 4 && productivity >= 70) || (mood <= 2 && productivity < 50)) {
          totalCorrelation++;
        }
        matchCount++;
      }
    }

    if (matchCount > 0) {
      final correlation = totalCorrelation / matchCount;
      insights.add(CrossFeatureInsight(
        insightType: 'mood_productivity',
        title: '情绪与生产力关联',
        description: correlation > 0.6
            ? '你的情绪状态与生产力高度相关。保持积极情绪可以显著提升工作效率。'
            : '你的情绪与生产力关联度一般，尝试找出影响你生产力的其他因素。',
        confidence: matchCount / 30.0,
        data: {'correlation': correlation, 'samples': matchCount},
      ));
    }

    return insights;
  }

  Future<List<CrossFeatureInsight>> generateHabitGoalInsights() async {
    final db = await _db;
    final insights = <CrossFeatureInsight>[];

    final habitRecords = await db.query('habits', limit: 50);

    final goalRecords = await db.query('goals', limit: 50);

    if (habitRecords.isEmpty || goalRecords.isEmpty) {
      return insights;
    }

    int completedHabits = 0;
    for (final habit in habitRecords) {
      final streak = (habit['current_streak'] as int?) ?? 0;
      if (streak >= 7) completedHabits++;
    }

    int completedGoals = 0;
    for (final goal in goalRecords) {
      final status = goal['status'] as String?;
      if (status == 'completed') completedGoals++;
    }

    final habitRate = completedHabits / habitRecords.length;
    final goalRate = completedGoals / goalRecords.length;

    if (habitRate > 0 && goalRate > 0) {
      insights.add(CrossFeatureInsight(
        insightType: 'habit_goal',
        title: '习惯与目标协同',
        description: habitRate > goalRate
            ? '你的习惯坚持得很好，但目标完成率相对较低。建议将目标分解为更小的习惯。'
            : '你的目标管理能力很强。继续保持这种节奏，习惯会进一步推动目标达成。',
        confidence: (habitRecords.length + goalRecords.length) / 100.0,
        data: {'habit_rate': habitRate, 'goal_rate': goalRate},
      ));
    }

    return insights;
  }

  Future<List<CrossFeatureInsight>> generateSleepPerformanceInsights() async {
    final db = await _db;
    final insights = <CrossFeatureInsight>[];

    final sleepRecords = await db.query('sleep_records', orderBy: 'date DESC', limit: 30);

    final productivityRecords = await db.query(
      'daily_productivity_scores',
      orderBy: 'date DESC',
      limit: 30,
    );

    if (sleepRecords.isEmpty || productivityRecords.isEmpty) {
      return insights;
    }

    final sleepByDate = <String, double>{};
    for (final record in sleepRecords) {
      final date = record['date'] as String;
      final duration = (record['duration_minutes'] as int?) ?? 0;
      sleepByDate[date] = duration / 60.0;
    }

    double goodDays = 0;
    double badDays = 0;

    for (final record in productivityRecords) {
      final date = record['date'] as String;
      if (sleepByDate.containsKey(date)) {
        final sleepHours = sleepByDate[date]!;
        final score = (record['overall_score'] as num?)?.toDouble() ?? 0;

        if (sleepHours >= 7 && score >= 70) {
          goodDays++;
        } else if (sleepHours < 6 && score < 50) {
          badDays++;
        }
      }
    }

    final total = goodDays + badDays;
    if (total > 0) {
      final correlation = goodDays / total;
      insights.add(CrossFeatureInsight(
        insightType: 'sleep_performance',
        title: '睡眠与表现关系',
        description: correlation > 0.6
            ? '充足的睡眠(7小时以上)对你的表现有明显的正面影响。保持良好睡眠习惯。'
            : '睡眠与表现的关联度一般，可能还有其他因素影响你的表现。',
        confidence: total / 30.0,
        data: {'correlation': correlation, 'good_days': goodDays, 'bad_days': badDays},
      ));
    }

    return insights;
  }

  Future<CrossFeatureAnalysis> getAllInsights() async {
    final insights = <CrossFeatureInsight>[];

    insights.addAll(await generateMoodProductivityInsights());
    insights.addAll(await generateHabitGoalInsights());
    insights.addAll(await generateSleepPerformanceInsights());

    return CrossFeatureAnalysis(
      insights: insights,
      correlations: {},
      patterns: insights.map((i) => i.insightType).toList(),
      recommendations: {},
    );
  }

  Future<int> saveInsight(CrossFeatureInsight insight) async {
    final db = await _db;
    return await db.insert('cross_feature_insights', insight.toMap());
  }

  Future<List<CrossFeatureInsight>> getSavedInsights() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'cross_feature_insights',
      orderBy: 'generated_at DESC',
    );
    return maps.map((map) => CrossFeatureInsight.fromMap(map)).toList();
  }
}
