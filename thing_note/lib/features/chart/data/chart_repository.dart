import 'package:thing_note/features/chart/domain/chart_data.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

class ChartRepository {
  List<ChartDataPoint> getDurationTrend(List<EpisodeRecord> records) {
    if (records.isEmpty) return [];

    // 按日期分组
    final byDate = <DateTime, int>{};
    for (final record in records) {
      final date = DateTime(
        record.occurredAt.year,
        record.occurredAt.month,
        record.occurredAt.day,
      );
      byDate[date] = (byDate[date] ?? 0) + record.durationSec;
    }

    // 排序并转换为数据点
    final sorted = byDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) => ChartDataPoint(
      date: e.key,
      value: e.value.toDouble(),
      label: _formatDate(e.key),
    )).toList();
  }

  List<ChartDataPoint> getRecordCountTrend(List<EpisodeRecord> records) {
    if (records.isEmpty) return [];

    final byDate = <DateTime, int>{};
    for (final record in records) {
      final date = DateTime(
        record.occurredAt.year,
        record.occurredAt.month,
        record.occurredAt.day,
      );
      byDate[date] = (byDate[date] ?? 0) + 1;
    }

    final sorted = byDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) => ChartDataPoint(
      date: e.key,
      value: e.value.toDouble(),
      label: _formatDate(e.key),
    )).toList();
  }

  List<ChartDataPoint> getHourlyDistribution(List<EpisodeRecord> records) {
    if (records.isEmpty) return [];

    final byHour = <int, int>{};
    for (final record in records) {
      final hour = record.occurredAt.hour;
      byHour[hour] = (byHour[hour] ?? 0) + 1;
    }

    // 创建 24 小时分布
    return List.generate(24, (hour) {
      return ChartDataPoint(
        date: DateTime(2024, 1, 1, hour),
        value: (byHour[hour] ?? 0).toDouble(),
        label: '${hour.toString().padLeft(2, '0')}:00',
      );
    });
  }

  WeeklyTrendData getWeeklyTrend(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return const WeeklyTrendData(
        dailyData: [],
        weekNumber: 0,
        totalRecords: 0,
        totalDurationSec: 0,
      );
    }

    // 获取当前周的开始日期（周一）
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    // 筛选本周数据
    final weekRecords = records.where((r) {
      final recordDate = DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
      return recordDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             recordDate.isBefore(weekStart.add(const Duration(days: 7)));
    }).toList();

    // 按天分组
    final byDay = <int, int>{};
    final byDayDuration = <int, int>{};
    for (final record in weekRecords) {
      final dayOfWeek = record.occurredAt.weekday;
      byDay[dayOfWeek] = (byDay[dayOfWeek] ?? 0) + 1;
      byDayDuration[dayOfWeek] = (byDayDuration[dayOfWeek] ?? 0) + record.durationSec;
    }

    // 创建本周每天的数据点
    final dailyData = List.generate(7, (index) {
      final dayOfWeek = index + 1;
      final date = weekStart.add(Duration(days: index));
      return ChartDataPoint(
        date: date,
        value: (byDay[dayOfWeek] ?? 0).toDouble(),
        label: _getDayName(dayOfWeek),
      );
    });

    return WeeklyTrendData(
      dailyData: dailyData,
      weekNumber: _getWeekNumber(now),
      totalRecords: weekRecords.length,
      totalDurationSec: weekRecords.fold(0, (sum, r) => sum + r.durationSec),
    );
  }

  RecordStatistics calculateStatistics(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return const RecordStatistics(
        totalRecords: 0,
        totalDurationSec: 0,
        averageDurationSec: 0,
        uniqueDays: 0,
        recordsByThingName: {},
      );
    }

    // 唯一天数
    final uniqueDays = records.map((r) =>
        DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day)).toSet().length;

    // 按事情名称统计
    final byThingName = <int?, int>{};
    for (final record in records) {
      byThingName[record.thingNameId] = (byThingName[record.thingNameId] ?? 0) + 1;
    }

    // 总时长
    final totalDuration = records.fold<int>(0, (sum, r) => sum + r.durationSec);

    // 最活跃小时
    final hourCounts = <int, int>{};
    for (final record in records) {
      hourCounts[record.occurredAt.hour] = (hourCounts[record.occurredAt.hour] ?? 0) + 1;
    }
    int? mostActiveHour;
    int maxHourCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxHourCount) {
        maxHourCount = count;
        mostActiveHour = hour;
      }
    });

    // 最活跃星期
    final dayCounts = <int, int>{};
    for (final record in records) {
      dayCounts[record.occurredAt.weekday] = (dayCounts[record.occurredAt.weekday] ?? 0) + 1;
    }
    int? mostActiveDay;
    int maxDayCount = 0;
    dayCounts.forEach((day, count) {
      if (count > maxDayCount) {
        maxDayCount = count;
        mostActiveDay = day;
      }
    });

    return RecordStatistics(
      totalRecords: records.length,
      totalDurationSec: totalDuration,
      averageDurationSec: records.isEmpty ? 0 : totalDuration / records.length,
      uniqueDays: uniqueDays,
      recordsByThingName: byThingName,
      mostActiveHour: mostActiveHour,
      mostActiveDayOfWeek: mostActiveDay,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek - 1];
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return ((daysDiff + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}