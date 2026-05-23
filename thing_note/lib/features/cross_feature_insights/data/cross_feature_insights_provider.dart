// Cross-Feature Insights feature
// Version: 1.0
// Description: 跨功能数据分析，发现不同功能模块之间的关联和洞察

import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Cross Feature Insights Provider
final crossFeatureInsightsProvider = FutureProvider<List<CrossFeatureInsight>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final insights = <CrossFeatureInsight>[];
  
  // Insight 1: Productivity vs Mood correlation
  final productivityMoodInsight = await _analyzeProductivityMoodCorrelation(db);
  if (productivityMoodInsight != null) insights.add(productivityMoodInsight);
  
  // Insight 2: Habit completion vs Goal progress
  final habitGoalInsight = await _analyzeHabitGoalCorrelation(db);
  if (habitGoalInsight != null) insights.add(habitGoalInsight);
  
  // Insight 3: Sleep quality impact on productivity
  final sleepProductivityInsight = await _analyzeSleepProductivityCorrelation(db);
  if (sleepProductivityInsight != null) insights.add(sleepProductivityInsight);
  
  // Insight 4: Location patterns
  final locationInsight = await _analyzeLocationPatterns(db);
  if (locationInsight != null) insights.add(locationInsight);
  
  // Insight 5: Tag usage trends
  final tagTrendInsight = await _analyzeTagTrends(db);
  if (tagTrendInsight != null) insights.add(tagTrendInsight);
  
  // Insight 6: Time patterns
  final timePatternInsight = await _analyzeTimePatterns(db);
  if (timePatternInsight != null) insights.add(timePatternInsight);
  
  return insights;
});

class CrossFeatureInsight {
  final String title;
  final String description;
  final String insightType;
  final double confidence;
  final String icon;
  final List<String> recommendations;

  CrossFeatureInsight({
    required this.title,
    required this.description,
    required this.insightType,
    required this.confidence,
    required this.icon,
    required this.recommendations,
  });
}

Future<CrossFeatureInsight?> _analyzeProductivityMoodCorrelation(Database db) async {
  // Get productivity scores
  final productivityScores = await db.query('daily_productivity_scores', limit: 30);
  
  // Get mood records
  final moodRecords = await db.query('mood_journals', limit: 30);
  
  if (productivityScores.length < 5 || moodRecords.length < 5) return null;
  
  // Calculate correlation
  int positiveDays = 0;
  int totalDays = 0;
  
  for (final ps in productivityScores) {
    final date = ps['date'] as String;
    final score = (ps['overall_score'] as num?)?.toDouble() ?? 0;
    
    final matchingMood = moodRecords.where((m) => m['date'] == date).toList();
    if (matchingMood.isNotEmpty) {
      totalDays++;
      final moodLevel = matchingMood.first['mood_level'] as int? ?? 3;
      
      if ((score >= 7 && moodLevel >= 4) || (score <= 4 && moodLevel <= 2)) {
        positiveDays++;
      }
    }
  }
  
  if (totalDays < 3) return null;
  
  final correlation = positiveDays / totalDays;
  
  return CrossFeatureInsight(
    title: '生产力与情绪关联',
    description: correlation > 0.6
        ? '你的高效率日往往伴随着好心情，这形成了正向循环'
        : correlation > 0.4
            ? '你的生产力和情绪存在一定关联'
            : '你的生产力和情绪相对独立',
    insightType: 'correlation',
    confidence: correlation,
    icon: '🧠',
    recommendations: correlation > 0.6
        ? ['继续保持这种正向循环', '在高情绪时安排挑战性任务']
        : ['尝试找出影响生产力的其他因素', '记录更多数据以获得更准确的分析'],
  );
}

Future<CrossFeatureInsight?> _analyzeHabitGoalCorrelation(Database db) async {
  final habits = await db.query('habits', limit: 10);
  final goals = await db.query('goals', limit: 10);
  
  if (habits.isEmpty || goals.isEmpty) return null;
  
  int completedHabits = 0;
  int activeGoals = 0;
  
  for (final habit in habits) {
    final status = habit['status'] as String?;
    if (status == 'completed') completedHabits++;
  }
  
  for (final goal in goals) {
    final status = goal['status'] as String?;
    if (status == 'active') activeGoals++;
  }
  
  final completionRate = habits.isNotEmpty ? completedHabits / habits.length : 0.0;
  final activeRate = goals.isNotEmpty ? activeGoals / goals.length : 1.0;
  
  return CrossFeatureInsight(
    title: '习惯与目标协同',
    description: completionRate > 0.7
        ? '你已完成大部分习惯，保持良好的节奏'
        : completionRate > 0.4
            ? '习惯完成率一般，可能需要调整计划'
            : '习惯完成率较低，建议从简单习惯开始',
    insightType: 'sync',
    confidence: completionRate,
    icon: '🎯',
    recommendations: [
      activeRate > 0.7 ? '目标进展良好，继续保持' : '考虑调整过于激进的目标',
      completionRate < 0.5 ? '尝试减少同时进行的习惯数量' : '保持当前节奏',
    ],
  );
}

Future<CrossFeatureInsight?> _analyzeSleepProductivityCorrelation(Database db) async {
  final sleepRecords = await db.query('sleep_records', limit: 14);
  // ignore: unused_local_variable
  final productivityScores = await db.query('daily_productivity_scores', limit: 14);
  
  if (sleepRecords.length < 7) return null;
  
  int totalSleepMinutes = 0;
  int avgMoodScore = 0;
  
  for (final record in sleepRecords) {
    final duration = record['duration_minutes'] as int? ?? 0;
    totalSleepMinutes += duration;
    avgMoodScore += (record['quality_score'] as int? ?? 3);
  }
  
  final avgSleepHours = totalSleepMinutes / sleepRecords.length / 60;
  final avgQuality = avgMoodScore / sleepRecords.length;
  
  String description;
  if (avgSleepHours >= 7 && avgQuality >= 4) {
    description = '你的睡眠质量很好，这有助于保持高效';
  } else if (avgSleepHours >= 6) {
    description = '睡眠时长充足，但质量可以进一步提升';
  } else {
    description = '睡眠不足可能影响你的日间表现';
  }
  
  return CrossFeatureInsight(
    title: '睡眠与表现',
    description: description,
    insightType: 'health',
    confidence: avgSleepHours >= 7 ? 0.9 : 0.6,
    icon: '😴',
    recommendations: avgSleepHours < 6
        ? ['尝试提前30分钟入睡', '避免睡前使用电子设备']
        : ['保持当前的睡眠习惯', '记录睡眠质量以获得更准确的分析'],
  );
}

Future<CrossFeatureInsight?> _analyzeLocationPatterns(Database db) async {
  final locations = await db.query('smart_locations', orderBy: 'visit_count DESC', limit: 5);
  
  if (locations.isEmpty) return null;
  
  final topLocation = locations.first;
  final locationName = topLocation['name'] as String? ?? '未知';
  final visitCount = topLocation['visit_count'] as int? ?? 0;
  
  return CrossFeatureInsight(
    title: '位置偏好',
    description: '你最常去的地点是「$locationName」，共访问$visitCount次',
    insightType: 'location',
    confidence: 0.8,
    icon: '📍',
    recommendations: [
      '考虑在常去地点创建更多相关记录',
      '尝试发现新的地点以增加生活多样性',
    ],
  );
}

Future<CrossFeatureInsight?> _analyzeTagTrends(Database db) async {
  final tagCounts = await db.rawQuery('''
    SELECT tag_name, COUNT(*) as count
    FROM record_tags
    GROUP BY tag_name
    ORDER BY count DESC
    LIMIT 10
  ''');
  
  if (tagCounts.isEmpty) return null;
  
  final topTag = tagCounts.first;
  final tagName = topTag['tag_name'] as String? ?? '无';
  final count = topTag['count'] as int? ?? 0;
  
  return CrossFeatureInsight(
    title: '热门标签',
    description: '你最常使用的标签是「$tagName」，共使用了$count次',
    insightType: 'tag',
    confidence: 0.9,
    icon: '🏷️',
    recommendations: [
      '考虑创建该标签的快捷方式',
      '探索使用较少的相关标签以发现新模式',
    ],
  );
}

Future<CrossFeatureInsight?> _analyzeTimePatterns(Database db) async {
  final records = await db.query('episode_records', limit: 50);
  
  if (records.length < 10) return null;
  
  final Map<int, int> hourDistribution = {};
  
  for (final record in records) {
    final occurredAt = DateTime.parse(record['occurred_at'] as String);
    hourDistribution[occurredAt.hour] = (hourDistribution[occurredAt.hour] ?? 0) + 1;
  }
  
  if (hourDistribution.isEmpty) return null;
  
  final sortedHours = hourDistribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  final peakHour = sortedHours.first.key;
  final peakLabel = peakHour < 12 ? '上午' : peakHour < 18 ? '下午' : '晚上';
  
  return CrossFeatureInsight(
    title: '记录时间偏好',
    description: '你倾向于在$peakLabel（$peakHour:00）记录事件',
    insightType: 'time',
    confidence: sortedHours.first.value > 10 ? 0.8 : 0.5,
    icon: '⏰',
    recommendations: [
      '建议在非高峰期也记录一些内容',
      '利用高峰时段进行批量记录',
    ],
  );
}