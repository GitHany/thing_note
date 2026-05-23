import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/multi_stat_card_models.dart';

/// 多维度统计卡片服务提供者
final multiStatCardServiceProvider = Provider<MultiStatCardService>((ref) {
  return MultiStatCardService(ref.read(databaseProvider.future));
});

/// 多维度统计卡片服务
class MultiStatCardService {
  final Future<Database> _db;

  MultiStatCardService(this._db);

  /// 获取统计数据
  Future<StatData> getStatData(StatType type, StatPeriod period) async {
    final db = await _db;
    final now = DateTime.now();

    // 确定时间范围
    DateTime startDate;
    final DateTime endDate = now;

    switch (period) {
      case StatPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case StatPeriod.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case StatPeriod.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case StatPeriod.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case StatPeriod.all:
        startDate = DateTime(2000);
        break;
    }

    // 获取当前周期的记录
    final records = await db.query(
      'episode_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // 获取上一周期的记录
    final periodDays = _getPeriodDays(period);
    final prevStartDate = startDate.subtract(Duration(days: periodDays));
    final prevEndDate = startDate.subtract(const Duration(days: 1));

    final prevRecords = await db.query(
      'episode_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [prevStartDate.toIso8601String(), prevEndDate.toIso8601String()],
    );

    dynamic value;
    dynamic previousValue;

    switch (type) {
      case StatType.recordCount:
        value = records.length;
        previousValue = prevRecords.length;
        break;
      case StatType.totalDuration:
        final totalSeconds = records.fold<int>(0, (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0));
        final prevSeconds = prevRecords.fold<int>(0, (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0));
        value = totalSeconds ~/ 60; // 分钟
        previousValue = prevSeconds ~/ 60;
        break;
      case StatType.activeDays:
        final activeDays = records.map((r) => DateTime.parse(r['created_at'] as String).day).toSet().length;
        final prevActiveDays = prevRecords.map((r) => DateTime.parse(r['created_at'] as String).day).toSet().length;
        value = activeDays;
        previousValue = prevActiveDays;
        break;
      case StatType.topThing:
        final thingCounts = <int, int>{};
        for (final record in records) {
          final thingId = record['thing_name_id'] as int?;
          if (thingId != null) {
            thingCounts[thingId] = (thingCounts[thingId] ?? 0) + 1;
          }
        }
        if (thingCounts.isNotEmpty) {
          final topThingId = thingCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          final thingNames = await db.query('thing_names', where: 'id = ?', whereArgs: [topThingId]);
          value = thingNames.isNotEmpty ? thingNames.first['name'] : '未知';
        } else {
          value = '无数据';
        }
        previousValue = null;
        break;
      case StatType.moodAverage:
        // 从 mood_entries 获取平均情绪
        final moodRecords = await db.query(
          'mood_entries',
          where: 'created_at >= ? AND created_at <= ?',
          whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        );
        if (moodRecords.isNotEmpty) {
          final avgMood = moodRecords.map((r) => r['mood_level'] as int).reduce((a, b) => a + b) / moodRecords.length;
          value = avgMood.toStringAsFixed(1);
        } else {
          value = '无数据';
        }
        previousValue = null;
        break;
      default:
        value = 0;
        previousValue = 0;
    }

    final changePercent = previousValue == null || previousValue == 0
        ? 0.0
        : ((value is int ? value : double.parse(value.toString())) - 
           (previousValue is int ? previousValue : double.parse(previousValue.toString()))) /
          (previousValue is int ? previousValue : double.parse(previousValue.toString())) * 100;

    // 生成趋势数据
    final trend = await _generateTrend(type, startDate, endDate);

    return StatData(
      type: type,
      value: value,
      previousValue: previousValue,
      changePercent: changePercent,
      trend: trend,
    );
  }

  Future<List<StatDataPoint>> _generateTrend(StatType type, DateTime start, DateTime end) async {
    final trend = <StatDataPoint>[];
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final dayStart = DateTime(current.year, current.month, current.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final db = await _db;
      final records = await db.query(
        'episode_records',
        where: 'created_at >= ? AND created_at < ?',
        whereArgs: [dayStart.toIso8601String(), dayEnd.toIso8601String()],
      );

      double dayValue = 0;
      switch (type) {
        case StatType.recordCount:
          dayValue = records.length.toDouble();
          break;
        case StatType.totalDuration:
          dayValue = records.fold<int>(0, (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0)) / 60;
          break;
        default:
          dayValue = records.length.toDouble();
      }

      trend.add(StatDataPoint(date: current, value: dayValue));
      current = current.add(const Duration(days: 1));
    }

    return trend;
  }

  int _getPeriodDays(StatPeriod period) {
    switch (period) {
      case StatPeriod.today:
        return 1;
      case StatPeriod.week:
        return 7;
      case StatPeriod.month:
        return 30;
      case StatPeriod.year:
        return 365;
      case StatPeriod.all:
        return 3650;
    }
  }

  /// 获取所有统计卡片数据
  Future<List<StatData>> getAllStats(StatPeriod period) async {
    const types = StatType.values;
    final stats = <StatData>[];

    for (final type in types) {
      try {
        final data = await getStatData(type, period);
        stats.add(data);
      } catch (e) {
        // 忽略错误，继续获取下一个
      }
    }

    return stats;
  }
}