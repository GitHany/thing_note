import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/time_insight_report_models.dart';

/// 时间洞察报告服务提供者
final timeInsightReportServiceProvider = Provider<TimeInsightReportService>((ref) {
  return TimeInsightReportService(ref.read(databaseProvider.future));
});

/// 时间洞察报告服务
class TimeInsightReportService {
  final Future<Database> _db;

  TimeInsightReportService(this._db);

  /// 生成报告
  Future<TimeInsightReport> generateReport(TimePeriod period) async {
    final db = await _db;
    final now = DateTime.now();

    // 确定时间范围
    DateTime startDate;
    final DateTime endDate = now;

    switch (period) {
      case TimePeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.thisWeek:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case TimePeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimePeriod.thisYear:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    // 获取记录
    final records = await db.query(
      'episode_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // 计算分布
    final distribution = await _calculateDistribution(records);

    // 分析模式
    final patterns = await _analyzePatterns(records);

    // 生成洞察
    final insights = await _generateInsights(records, distribution);

    // 生成对比
    ComparisonReport? comparison;
    if (period == TimePeriod.thisWeek) {
      comparison = await _generateWeeklyComparison();
    }

    return TimeInsightReport(
      generatedAt: now,
      period: period,
      distribution: distribution,
      patterns: patterns,
      insights: insights,
      comparison: comparison,
    );
  }

  Future<TimeDistribution> _calculateDistribution(List<Map<String, dynamic>> records) async {
    final hourDist = <String, int>{};
    final dayDist = <String, int>{};
    final tagDist = <String, int>{};
    final thingNameDist = <String, int>{};

    for (final record in records) {
      final createdAt = DateTime.parse(record['created_at'] as String);
      final duration = (record['duration_sec'] as int?) ?? 0;

      // 小时分布
      final hourKey = '${createdAt.hour}:00';
      hourDist[hourKey] = (hourDist[hourKey] ?? 0) + (duration ~/ 60);

      // 星期分布
      final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final dayKey = dayNames[createdAt.weekday - 1];
      dayDist[dayKey] = (dayDist[dayKey] ?? 0) + (duration ~/ 60);

      // 事情名称分布
      final thingNameId = record['thing_name_id'];
      if (thingNameId != null) {
        final thingNames = await _db.then((db) => db.query(
          'thing_names',
          where: 'id = ?',
          whereArgs: [thingNameId],
        ));
        if (thingNames.isNotEmpty) {
          final name = thingNames.first['name'] as String;
          thingNameDist[name] = (thingNameDist[name] ?? 0) + 1;
        }
      }
    }

    return TimeDistribution(
      hourDistribution: hourDist,
      dayDistribution: dayDist,
      tagDistribution: tagDist,
      thingNameDistribution: thingNameDist,
    );
  }

  Future<List<TimePattern>> _analyzePatterns(List<Map<String, dynamic>> records) async {
    final patterns = <TimePattern>[];

    if (records.isEmpty) return patterns;

    // 分析早起型/夜猫子型
    int morningCount = 0;
    int nightCount = 0;

    for (final record in records) {
      final createdAt = DateTime.parse(record['created_at'] as String);
      if (createdAt.hour >= 5 && createdAt.hour < 10) {
        morningCount++;
      } else if (createdAt.hour >= 22 || createdAt.hour < 2) {
        nightCount++;
      }
    }

    final total = records.length;
    if (morningCount / total > 0.3) {
      patterns.add(TimePattern(
        name: '早起鸟',
        description: '您习惯在早晨进行记录',
        confidence: morningCount / total,
        type: PatternType.morningPerson,
        evidence: ['早晨记录占比 ${(morningCount / total * 100).toStringAsFixed(0)}%'],
      ));
    }

    if (nightCount / total > 0.3) {
      patterns.add(TimePattern(
        name: '夜猫子',
        description: '您习惯在夜间进行记录',
        confidence: nightCount / total,
        type: PatternType.nightOwl,
        evidence: ['夜间记录占比 ${(nightCount / total * 100).toStringAsFixed(0)}%'],
      ));
    }

    // 分析周末/工作日活跃度
    int weekdayCount = 0;
    int weekendCount = 0;

    for (final record in records) {
      final createdAt = DateTime.parse(record['created_at'] as String);
      if (createdAt.weekday <= 5) {
        weekdayCount++;
      } else {
        weekendCount++;
      }
    }

    final weekdayRatio = weekdayCount / 5;
    final weekendRatio = weekendCount / 2;

    if (weekdayRatio > weekendRatio * 1.5) {
      patterns.add(TimePattern(
        name: '工作日专注',
        description: '您在工作日更加活跃',
        confidence: weekdayRatio / (weekdayRatio + weekendRatio),
        type: PatternType.weekdayFocused,
        evidence: ['工作日平均 ${weekdayRatio.toStringAsFixed(1)} 条/天', '周末平均 ${weekendRatio.toStringAsFixed(1)} 条/天'],
      ));
    } else if (weekendRatio > weekdayRatio * 1.5) {
      patterns.add(TimePattern(
        name: '周末活跃',
        description: '您在周末更加活跃',
        confidence: weekendRatio / (weekdayRatio + weekendRatio),
        type: PatternType.weekEndActive,
        evidence: ['周末平均 ${weekendRatio.toStringAsFixed(1)} 条/天', '工作日平均 ${weekdayRatio.toStringAsFixed(1)} 条/天'],
      ));
    }

    return patterns;
  }

  Future<List<ActivityInsight>> _generateInsights(
    List<Map<String, dynamic>> records,
    TimeDistribution distribution,
  ) async {
    final insights = <ActivityInsight>[];

    if (records.isEmpty) {
      insights.add(ActivityInsight(
        category: '记录',
        title: '开始记录',
        description: '您还没有任何记录',
        type: InsightType.alert,
        suggestion: '记录您的第一个事件，开始追踪您的生活',
      ));
      return insights;
    }

    // 记录总数洞察
    if (records.length >= 100) {
      insights.add(ActivityInsight(
        category: '记录',
        title: '记录达人',
        description: '您已经记录了 ${records.length} 条事件',
        type: InsightType.achievement,
        suggestion: '继续保持！',
      ));
    } else if (records.length >= 50) {
      insights.add(ActivityInsight(
        category: '记录',
        title: '坚持不懈',
        description: '您已经记录了 ${records.length} 条事件',
        type: InsightType.highlight,
      ));
    }

    // 最活跃时间洞察
    if (distribution.hourDistribution.isNotEmpty) {
      final sortedHours = distribution.hourDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedHours.isNotEmpty) {
        final peakHour = sortedHours.first;
        insights.add(ActivityInsight(
          category: '时间',
          title: '黄金时间',
          description: '您在 ${peakHour.key} 最活跃',
          type: InsightType.highlight,
          suggestion: '在这个时间段安排重要任务',
        ));
      }
    }

    // 周末洞察
    final weekendMinutes = (distribution.dayDistribution['周六'] ?? 0) +
        (distribution.dayDistribution['周日'] ?? 0);
    final weekdayAvgMinutes = distribution.dayDistribution.entries
        .where((e) => e.key != '周六' && e.key != '周日')
        .fold(0, (sum, e) => sum + e.value) / 5;

    if (weekendMinutes > weekdayAvgMinutes * 1.5) {
      insights.add(ActivityInsight(
        category: '时间',
        title: '周末充电',
        description: '您在周末更加活跃',
        type: InsightType.improvement,
        suggestion: '考虑在工作日也保持一定的活跃度',
      ));
    }

    return insights;
  }

  Future<ComparisonReport?> _generateWeeklyComparison() async {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekRecords = await _getRecordsInRange(
      DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day),
      now,
    );

    final lastWeekRecords = await _getRecordsInRange(
      DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day),
      DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day - 1),
    );

    if (lastWeekRecords.isEmpty) return null;

    final thisWeekMinutes = thisWeekRecords.fold<int>(
      0,
      (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0) ~/ 60,
    );
    final lastWeekMinutes = lastWeekRecords.fold<int>(
      0,
      (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0) ~/ 60,
    );

    final recordChange = thisWeekRecords.length - lastWeekRecords.length;
    final recordChangePercent = (recordChange / lastWeekRecords.length) * 100;
    final minuteChange = thisWeekMinutes - lastWeekMinutes;

    return ComparisonReport(
      comparedPeriod: TimePeriod.thisWeek,
      totalRecordsChange: recordChange,
      totalRecordsChangePercent: recordChangePercent,
      totalMinutesChange: minuteChange,
    );
  }

  Future<List<Map<String, dynamic>>> _getRecordsInRange(DateTime start, DateTime end) async {
    final db = await _db;
    return db.query(
      'episode_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  /// 获取周对比数据
  Future<WeeklyComparison> getWeeklyComparison() async {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekRecords = await _getRecordsInRange(
      DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day),
      now,
    );

    final lastWeekRecords = await _getRecordsInRange(
      DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day),
      DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day - 1),
    );

    final thisWeekMinutes = thisWeekRecords.fold<int>(
      0,
      (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0) ~/ 60,
    );
    final lastWeekMinutes = lastWeekRecords.fold<int>(
      0,
      (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0) ~/ 60,
    );

    final recordChangePercent = lastWeekRecords.isEmpty
        ? 100.0
        : ((thisWeekRecords.length - lastWeekRecords.length) / lastWeekRecords.length) * 100;
    final minuteChangePercent = lastWeekMinutes == 0
        ? 100.0
        : ((thisWeekMinutes - lastWeekMinutes) / lastWeekMinutes) * 100;

    return WeeklyComparison(
      thisWeekRecords: thisWeekRecords.length,
      lastWeekRecords: lastWeekRecords.length,
      thisWeekMinutes: thisWeekMinutes,
      lastWeekMinutes: lastWeekMinutes,
      recordChangePercent: recordChangePercent,
      minuteChangePercent: minuteChangePercent,
    );
  }
}