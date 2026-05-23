import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 数据仪表盘服务
class DashboardService {
  final AsyncValue<Database> _dbAsync;

  DashboardService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取今日概览数据
  Future<DashboardData> getTodayDashboard() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _getDashboardForRange(todayStart, todayEnd);
  }

  /// 获取本周概览数据
  Future<DashboardData> getWeeklyDashboard() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDate.add(const Duration(days: 7));

    return _getDashboardForRange(weekStartDate, weekEnd);
  }

  /// 获取本月概览数据
  Future<DashboardData> getMonthlyDashboard() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    return _getDashboardForRange(monthStart, monthEnd);
  }

  Future<DashboardData> _getDashboardForRange(DateTime start, DateTime end) async {
    final db = await _db;

    // 获取记录统计
    final recordsResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as recordCount,
        SUM(duration_sec) as totalDuration,
        SUM(LENGTH(photo_paths) - LENGTH(REPLACE(photo_paths, ',', '')) + 1) as photoCount,
        SUM(LENGTH(video_paths) - LENGTH(REPLACE(video_paths, ',', '')) + 1) as videoCount
      FROM episode_records
      WHERE occurred_at >= ? AND occurred_at < ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // 获取最常用的事情名称
    final topThingNames = await db.rawQuery('''
      SELECT tn.name, COUNT(*) as count
      FROM episode_records r
      INNER JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE r.occurred_at >= ? AND r.occurred_at < ?
      GROUP BY tn.id
      ORDER BY count DESC
      LIMIT 5
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // 获取最常用的标签
    final topTags = await db.rawQuery('''
      SELECT t.name, COUNT(*) as count
      FROM episode_records r
      INNER JOIN record_tags rt ON r.id = rt.record_id
      INNER JOIN tags t ON rt.tag_id = t.id
      WHERE r.occurred_at >= ? AND r.occurred_at < ?
      GROUP BY t.id
      ORDER BY count DESC
      LIMIT 5
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // 获取每日记录数趋势
    final dailyTrend = await db.rawQuery('''
      SELECT DATE(occurred_at) as date, COUNT(*) as count
      FROM episode_records
      WHERE occurred_at >= ? AND occurred_at < ?
      GROUP BY DATE(occurred_at)
      ORDER BY date
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // 获取活跃天数
    final activeDays = await db.rawQuery('''
      SELECT COUNT(DISTINCT DATE(occurred_at)) as count
      FROM episode_records
      WHERE occurred_at >= ? AND occurred_at < ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final recordData = recordsResult.first;
    final activeDaysData = activeDays.first;

    return DashboardData(
      recordCount: recordData['recordCount'] as int? ?? 0,
      totalDurationSec: recordData['totalDuration'] as int? ?? 0,
      photoCount: _parseMediaCount(recordData['photoCount']),
      videoCount: _parseMediaCount(recordData['videoCount']),
      topThingNames: topThingNames.map((r) => TopItem(
        name: r['name'] as String,
        count: r['count'] as int,
      )).toList(),
      topTags: topTags.map((r) => TopItem(
        name: r['name'] as String,
        count: r['count'] as int,
      )).toList(),
      dailyTrend: dailyTrend.map((r) => DailyTrendItem(
        date: DateTime.parse(r['date'] as String),
        count: r['count'] as int,
      )).toList(),
      activeDays: activeDaysData['count'] as int? ?? 0,
      startDate: start,
      endDate: end,
    );
  }

  int _parseMediaCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String && value.isEmpty) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// 获取实时统计数据
  Future<RealtimeStats> getRealtimeStats() async {
    final db = await _db;

    final totalRecords = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records');
    final totalDuration = await db.rawQuery('SELECT SUM(duration_sec) as total FROM episode_records');
    final favorites = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records WHERE is_favorite = 1');
    final reminders = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records WHERE has_reminder = 1');

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayRecords = await db.rawQuery(
      'SELECT COUNT(*) as count FROM episode_records WHERE occurred_at >= ?',
      [todayStart.toIso8601String()],
    );

    // 计算连续记录天数
    final streak = await _calculateStreak();

    return RealtimeStats(
      totalRecords: totalRecords.first['count'] as int? ?? 0,
      totalDurationSec: totalDuration.first['total'] as int? ?? 0,
      favoritesCount: favorites.first['count'] as int? ?? 0,
      remindersCount: reminders.first['count'] as int? ?? 0,
      todayRecords: todayRecords.first['count'] as int? ?? 0,
      currentStreak: streak,
    );
  }

  Future<int> _calculateStreak() async {
    final db = await _db;
    
    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(occurred_at) as date
      FROM episode_records
      ORDER BY date DESC
    ''');

    if (result.isEmpty) return 0;

    int streak = 0;
    var expectedDate = DateTime.now();

    for (final row in result) {
      final recordDate = DateTime.parse(row['date'] as String);
      final recordDateOnly = DateTime(recordDate.year, recordDate.month, recordDate.day);
      final expectedDateOnly = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);

      if (recordDateOnly == expectedDateOnly || 
          recordDateOnly == expectedDateOnly.subtract(const Duration(days: 1))) {
        streak++;
        expectedDate = recordDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

/// 仪表盘数据模型
class DashboardData {
  final int recordCount;
  final int totalDurationSec;
  final int photoCount;
  final int videoCount;
  final List<TopItem> topThingNames;
  final List<TopItem> topTags;
  final List<DailyTrendItem> dailyTrend;
  final int activeDays;
  final DateTime startDate;
  final DateTime endDate;

  const DashboardData({
    required this.recordCount,
    required this.totalDurationSec,
    required this.photoCount,
    required this.videoCount,
    this.topThingNames = const [],
    this.topTags = const [],
    this.dailyTrend = const [],
    this.activeDays = 0,
    required this.startDate,
    required this.endDate,
  });

  String get formattedDuration {
    final hours = totalDurationSec ~/ 3600;
    final minutes = (totalDurationSec % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }
}

/// 热门项目
class TopItem {
  final String name;
  final int count;

  const TopItem({required this.name, required this.count});
}

/// 每日趋势项
class DailyTrendItem {
  final DateTime date;
  final int count;

  const DailyTrendItem({required this.date, required this.count});
}

/// 实时统计数据
class RealtimeStats {
  final int totalRecords;
  final int totalDurationSec;
  final int favoritesCount;
  final int remindersCount;
  final int todayRecords;
  final int currentStreak;

  const RealtimeStats({
    required this.totalRecords,
    required this.totalDurationSec,
    required this.favoritesCount,
    required this.remindersCount,
    required this.todayRecords,
    required this.currentStreak,
  });

  String get formattedTotalDuration {
    final hours = totalDurationSec ~/ 3600;
    if (hours > 0) {
      return '$hours小时+';
    }
    final minutes = totalDurationSec ~/ 60;
    return '$minutes分钟';
  }
}

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DashboardService(dbAsync);
});