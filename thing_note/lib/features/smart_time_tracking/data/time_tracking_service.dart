import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_time_tracking/domain/time_tracking_models.dart';

/// 时间追踪服务 Provider
final smartTimeTrackingServiceProvider = Provider<SmartTimeTrackingService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartTimeTrackingService(dbAsync);
});

/// 时间追踪统计 Provider
final timeTrackingStatsProvider = FutureProvider<TimeTrackingStats>((ref) async {
  final service = ref.watch(smartTimeTrackingServiceProvider);
  return service.getWeeklyStats();
});

/// 时间段分布 Provider
final periodDistributionProvider = FutureProvider<PeriodDistribution>((ref) async {
  final service = ref.watch(smartTimeTrackingServiceProvider);
  return service.getPeriodDistribution();
});

/// Top 活动统计 Provider
final topActivitiesProvider = FutureProvider<List<ActivityTimeStat>>((ref) async {
  final service = ref.watch(smartTimeTrackingServiceProvider);
  return service.getTopActivities(limit: 10);
});

class SmartTimeTrackingService {
  final AsyncValue<Database> _dbAsync;

  SmartTimeTrackingService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 从记录数据自动生成时间追踪
  Future<void> generateFromRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;

    // 查询指定时间范围内的所有记录
    final records = await db.query(
      'episode_records',
      where: 'occurred_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    // 获取事情名称映射
    final thingNames = await db.query('thing_names');
    final thingNameMap = <int, String>{};
    for (final tn in thingNames) {
      thingNameMap[tn['id'] as int] = tn['name'] as String;
    }

    // 为每条记录生成时间追踪
    for (final record in records) {
      final recordId = record['id'] as int;
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      final durationSec = record['duration_sec'] as int? ?? 0;
      final thingNameId = record['thing_name_id'] as int?;
      final thingName = thingNameId != null 
          ? (thingNameMap[thingNameId] ?? '默认') 
          : '默认';
      final durationMinutes = (durationSec / 60).ceil();
      final periodType = PeriodType.fromTime(occurredAt).value;

      // 检查是否已存在
      final existing = await db.query(
        'time_tracking_entries',
        where: 'record_id = ?',
        whereArgs: [recordId],
      );

      if (existing.isEmpty && durationMinutes > 0) {
        await db.insert('time_tracking_entries', {
          'record_id': recordId,
          'thing_name': thingName,
          'duration_minutes': durationMinutes,
          'period_type': periodType,
          'tracked_at': occurredAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  /// 获取周统计数据
  Future<TimeTrackingStats> getWeeklyStats() async {
    final db = await _db;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final entries = await db.query(
      'time_tracking_entries',
      where: 'tracked_at BETWEEN ? AND ?',
      whereArgs: [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()],
    );

    int totalMinutes = 0;
    final activityMinutes = <String, int>{};
    final periodMinutes = <String, int>{};

    for (final entry in entries) {
      final minutes = entry['duration_minutes'] as int;
      totalMinutes += minutes;

      final thingName = entry['thing_name'] as String;
      activityMinutes[thingName] = (activityMinutes[thingName] ?? 0) + minutes;

      final period = entry['period_type'] as String;
      periodMinutes[period] = (periodMinutes[period] ?? 0) + minutes;
    }

    // 计算效率评分（基于活动多样性）
    final efficiencyScore = _calculateEfficiencyScore(activityMinutes, totalMinutes);

    return TimeTrackingStats(
      totalMinutes: totalMinutes,
      recordCount: entries.length,
      activityCount: activityMinutes.length,
      efficiencyScore: efficiencyScore,
      topActivities: activityMinutes.entries
          .map((e) => ActivityTimeStat(name: e.key, minutes: e.value))
          .toList()
        ..sort((a, b) => b.minutes.compareTo(a.minutes)),
      periodMinutes: periodMinutes,
      periodStart: startOfWeek,
      periodEnd: endOfWeek,
    );
  }

  double _calculateEfficiencyScore(Map<String, int> activityMinutes, int totalMinutes) {
    if (totalMinutes == 0 || activityMinutes.isEmpty) return 0.0;

    // 简单效率评分：基于活动多样性
    // 理想情况下，一天内应有多个不同的活动
    final uniqueActivities = activityMinutes.length;
    final avgMinutesPerActivity = totalMinutes / uniqueActivities;

    // 如果平均每项活动时间在30-180分钟之间，效率较高
    if (avgMinutesPerActivity >= 30 && avgMinutesPerActivity <= 180) {
      return (80 + (uniqueActivities * 5).clamp(0, 15)).toDouble();
    }
    return (50 + (uniqueActivities * 3).clamp(0, 10)).toDouble();
  }

  /// 获取时间段分布
  Future<PeriodDistribution> getPeriodDistribution() async {
    final db = await _db;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));

    final entries = await db.query(
      'time_tracking_entries',
      where: 'tracked_at >= ?',
      whereArgs: [start.toIso8601String()],
    );

    int morning = 0, afternoon = 0, evening = 0, night = 0;

    for (final entry in entries) {
      final minutes = entry['duration_minutes'] as int;
      final period = entry['period_type'] as String;

      switch (period) {
        case 'morning':
          morning += minutes;
        case 'afternoon':
          afternoon += minutes;
        case 'evening':
          evening += minutes;
        case 'night':
          night += minutes;
      }
    }

    return PeriodDistribution(
      morning: morning,
      afternoon: afternoon,
      evening: evening,
      night: night,
    );
  }

  /// 获取 Top 活动统计
  Future<List<ActivityTimeStat>> getTopActivities({int limit = 10}) async {
    final db = await _db;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));

    final result = await db.rawQuery('''
      SELECT thing_name, SUM(duration_minutes) as total_minutes
      FROM time_tracking_entries
      WHERE tracked_at >= ?
      GROUP BY thing_name
      ORDER BY total_minutes DESC
      LIMIT ?
    ''', [start.toIso8601String(), limit]);

    return result.map((row) => ActivityTimeStat(
      name: row['thing_name'] as String,
      minutes: row['total_minutes'] as int,
    )).toList();
  }

  /// 获取日趋势数据
  Future<List<DailyTimeTrend>> getDailyTrend({int days = 30}) async {
    final db = await _db;
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    final result = await db.rawQuery('''
      SELECT DATE(tracked_at) as date, SUM(duration_minutes) as total_minutes, COUNT(*) as record_count
      FROM time_tracking_entries
      WHERE tracked_at >= ?
      GROUP BY DATE(tracked_at)
      ORDER BY date ASC
    ''', [start.toIso8601String()]);

    return result.map((row) => DailyTimeTrend(
      date: DateTime.parse(row['date'] as String),
      totalMinutes: row['total_minutes'] as int,
      recordCount: row['record_count'] as int,
    )).toList();
  }

  /// 添加手动时间追踪
  Future<int> addTimeTracking(TimeTrackingEntry entry) async {
    final db = await _db;
    return db.insert('time_tracking_entries', entry.toMap()..remove('id'));
  }

  /// 删除时间追踪
  Future<int> deleteTimeTracking(int id) async {
    final db = await _db;
    return db.delete('time_tracking_entries', where: 'id = ?', whereArgs: [id]);
  }
}

/// 时间追踪统计数据模型
class TimeTrackingStats {
  final int totalMinutes;
  final int recordCount;
  final int activityCount;
  final double efficiencyScore;
  final List<ActivityTimeStat> topActivities;
  final Map<String, int> periodMinutes;
  final DateTime periodStart;
  final DateTime periodEnd;

  TimeTrackingStats({
    required this.totalMinutes,
    required this.recordCount,
    required this.activityCount,
    required this.efficiencyScore,
    required this.topActivities,
    required this.periodMinutes,
    required this.periodStart,
    required this.periodEnd,
  });

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }

  String get formattedEfficiency {
    return '${efficiencyScore.toStringAsFixed(0)}%';
  }
}

/// 活动时间统计
class ActivityTimeStat {
  final String name;
  final int minutes;

  ActivityTimeStat({required this.name, required this.minutes});

  String get formattedDuration {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// 时间段分布
class PeriodDistribution {
  final int morning;
  final int afternoon;
  final int evening;
  final int night;

  PeriodDistribution({
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.night,
  });

  int get total => morning + afternoon + evening + night;

  Map<String, double> get percentages {
    if (total == 0) return {};
    return {
      'morning': morning / total,
      'afternoon': afternoon / total,
      'evening': evening / total,
      'night': night / total,
    };
  }
}

/// 日趋势数据
class DailyTimeTrend {
  final DateTime date;
  final int totalMinutes;
  final int recordCount;

  DailyTimeTrend({
    required this.date,
    required this.totalMinutes,
    required this.recordCount,
  });

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}