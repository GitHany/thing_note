// Mood-Activity Correlation feature
// Version: 1.0
// Description: 分析活动与情绪的关联性，发现哪些活动对情绪有正面或负面影响

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Mood Correlation Provider
final moodCorrelationProvider = FutureProvider<List<MoodCorrelation>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // Query mood entries with linked records
  final moodEntries = await db.query('mood_journals', orderBy: 'date DESC', limit: 100);
  
  // Calculate correlations between activities and mood
  final correlations = <MoodCorrelation>[];
  final activityMoodMap = <String, List<int>>{};
  
  for (final entry in moodEntries) {
    final linkedRecordId = entry['linked_record_id'] as int?;
    if (linkedRecordId != null) {
      final record = await db.query(
        'episode_records',
        where: 'id = ?',
        whereArgs: [linkedRecordId],
      );
      if (record.isNotEmpty) {
        final thingNameId = record.first['thing_name_id'] as int?;
        if (thingNameId != null) {
          final thingName = await db.query(
            'thing_names',
            where: 'id = ?',
            whereArgs: [thingNameId],
          );
          if (thingName.isNotEmpty) {
            final activityName = thingName.first['name'] as String;
            final moodLevel = entry['mood_level'] as int;
            
            if (!activityMoodMap.containsKey(activityName)) {
              activityMoodMap[activityName] = [];
            }
            activityMoodMap[activityName]!.add(moodLevel);
          }
        }
      }
    }
  }
  
  // Calculate correlation for each activity
  for (final entry in activityMoodMap.entries) {
    if (entry.value.length >= 3) {
      final avgMood = entry.value.reduce((a, b) => a + b) / entry.value.length;
      correlations.add(MoodCorrelation(
        activityName: entry.key,
        avgMoodLevel: avgMood,
        sampleCount: entry.value.length,
        impactScore: _calculateImpactScore(avgMood),
        trend: _calculateTrend(entry.value),
      ));
    }
  }
  
  // Sort by sample count and impact
  correlations.sort((a, b) => b.sampleCount.compareTo(a.sampleCount));
  
  return correlations;
});

final bestActivitiesProvider = FutureProvider<List<ActivityInsight>>((ref) async {
  final correlations = await ref.watch(moodCorrelationProvider.future);
  
  // Filter positive activities
  return correlations
      .where((c) => c.impactScore > 0.3)
      .map((c) => ActivityInsight(
        name: c.activityName,
        moodBoost: c.impactScore,
        reason: c.avgMoodLevel >= 4 ? '显著提升情绪' : '对情绪有正面影响',
        sampleCount: c.sampleCount,
      ))
      .take(5)
      .toList();
});

final activitiesToAvoidProvider = FutureProvider<List<ActivityInsight>>((ref) async {
  final correlations = await ref.watch(moodCorrelationProvider.future);
  
  // Filter negative activities
  return correlations
      .where((c) => c.impactScore < -0.3)
      .map((c) => ActivityInsight(
        name: c.activityName,
        moodBoost: c.impactScore,
        reason: c.avgMoodLevel <= 2.5 ? '情绪显著下降' : '对情绪有负面影响',
        sampleCount: c.sampleCount,
      ))
      .take(5)
      .toList();
});

class MoodCorrelation {
  final String activityName;
  final double avgMoodLevel;
  final int sampleCount;
  final double impactScore;
  final String trend;

  MoodCorrelation({
    required this.activityName,
    required this.avgMoodLevel,
    required this.sampleCount,
    required this.impactScore,
    required this.trend,
  });
}

class ActivityInsight {
  final String name;
  final double moodBoost;
  final String reason;
  final int sampleCount;

  ActivityInsight({
    required this.name,
    required this.moodBoost,
    required this.reason,
    required this.sampleCount,
  });
}

double _calculateImpactScore(double avgMood) {
  // Assuming neutral is 3, calculate impact from baseline
  return (avgMood - 3.0) / 3.0; // Normalize to -1 to 1 range
}

String _calculateTrend(List<int> moods) {
  if (moods.length < 3) return '数据不足';
  
  final firstHalf = moods.sublist(0, moods.length ~/ 2);
  final secondHalf = moods.sublist(moods.length ~/ 2);
  
  final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
  final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
  
  final diff = secondAvg - firstAvg;
  if (diff > 0.3) return '↑ 上升趋势';
  if (diff < -0.3) return '↓ 下降趋势';
  return '→ 稳定';
}

// Time Audit System Provider
final timeAuditProvider = FutureProvider<TimeAudit>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();
  
  // Get records for this week
  final records = await db.query(
    'episode_records',
    where: 'occurred_at >= ?',
    whereArgs: [weekStartStr],
    orderBy: 'occurred_at ASC',
  );
  
  // Analyze time distribution
  final hourDistribution = <int, int>{};
  final dayDistribution = <int, int>{};
  final thingDistribution = <String, int>{};
  int totalMinutes = 0;
  
  for (final record in records) {
    final occurredAt = DateTime.parse(record['occurred_at'] as String);
    final duration = (record['duration_sec'] as int? ?? 0) ~/ 60;
    
    hourDistribution[occurredAt.hour] = (hourDistribution[occurredAt.hour] ?? 0) + duration;
    dayDistribution[occurredAt.weekday] = (dayDistribution[occurredAt.weekday] ?? 0) + duration;
    totalMinutes += duration;
    
    final thingNameId = record['thing_name_id'] as int?;
    if (thingNameId != null) {
      final thingNames = await db.query(
        'thing_names',
        where: 'id = ?',
        whereArgs: [thingNameId],
      );
      if (thingNames.isNotEmpty) {
        final name = thingNames.first['name'] as String;
        thingDistribution[name] = (thingDistribution[name] ?? 0) + duration;
      }
    }
  }
  
  // Find peak hours
  final sortedHours = hourDistribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final peakHours = sortedHours.take(3).map((e) => '${e.key}:00').toList();
  
  // Find most productive day
  final sortedDays = dayDistribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final bestDay = sortedDays.isNotEmpty 
      ? _getDayName(sortedDays.first.key) 
      : '未知';
  
  // Find top activities
  final sortedThings = thingDistribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topActivities = sortedThings.take(5).toList()
      .map((e) => TimeActivity(name: e.key, minutes: e.value))
      .toList();
  
  return TimeAudit(
    totalMinutes: totalMinutes,
    recordCount: records.length,
    peakHours: peakHours,
    bestDay: bestDay,
    topActivities: topActivities,
    hourDistribution: hourDistribution,
    dayDistribution: dayDistribution,
    averagePerDay: records.isNotEmpty ? totalMinutes ~/ 7 : 0,
  );
});

class TimeAudit {
  final int totalMinutes;
  final int recordCount;
  final List<String> peakHours;
  final String bestDay;
  final List<TimeActivity> topActivities;
  final Map<int, int> hourDistribution;
  final Map<int, int> dayDistribution;
  final int averagePerDay;

  TimeAudit({
    required this.totalMinutes,
    required this.recordCount,
    required this.peakHours,
    required this.bestDay,
    required this.topActivities,
    required this.hourDistribution,
    required this.dayDistribution,
    required this.averagePerDay,
  });
  
  double get totalHours => totalMinutes / 60.0;
}

class TimeActivity {
  final String name;
  final int minutes;

  TimeActivity({required this.name, required this.minutes});
}

String _getDayName(int weekday) {
  const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return days[weekday - 1];
}