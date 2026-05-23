import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 数据分析报告服务
class ReportService {
  final AsyncValue<Database> _dbAsync;

  ReportService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 生成每日报告
  Future<Report> generateDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final records = await _getRecordsInRange(startOfDay, endOfDay);
    final moodEntries = await _getMoodEntriesInRange(startOfDay, endOfDay);
    final habits = await _getHabitsInRange(startOfDay, endOfDay);

    final totalDuration = records.fold<int>(0, (sum, r) => sum + (r['duration_sec'] as int? ?? 0));
    final totalPhotos = records.fold<int>(0, (sum, r) => sum + _countPhotos(r['photo_paths'] as String?));
    final totalVideos = records.fold<int>(0, (sum, r) => sum + _countVideos(r['video_paths'] as String?));

    // 获取最常用的事情名称
    final topThingNames = await _getTopThingNames(startOfDay, endOfDay, limit: 5);

    // 获取最常用的标签
    final topTags = await _getTopTags(startOfDay, endOfDay, limit: 5);

    return Report(
      title: '${date.month}月${date.day}日报告',
      date: date,
      recordCount: records.length,
      totalDurationSec: totalDuration,
      photoCount: totalPhotos,
      videoCount: totalVideos,
      averageDuration: records.isNotEmpty ? totalDuration ~/ records.length : 0,
      topThingNames: topThingNames,
      topTags: topTags,
      moodAverage: moodEntries.isNotEmpty 
          ? moodEntries.fold<double>(0, (sum, m) => sum + _getMoodValue(m['mood'] as String)) / moodEntries.length
          : null,
      habitsCompleted: habits.where((h) => h['last_completed_at'] != null).length,
      totalHabits: habits.length,
    );
  }

  /// 生成周报告
  Future<Report> generateWeeklyReport(DateTime weekStart) async {
    final startOfWeek = weekStart;
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final dailyReports = <Report>[];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final record = await generateDailyReport(date);
      dailyReports.add(record);
    }

    final totalRecords = dailyReports.fold<int>(0, (sum, r) => sum + r.recordCount);
    final totalDuration = dailyReports.fold<int>(0, (sum, r) => sum + r.totalDurationSec);
    final totalPhotos = dailyReports.fold<int>(0, (sum, r) => sum + r.photoCount);
    final habitsCompleted = dailyReports.fold<int>(0, (sum, r) => sum + r.habitsCompleted);

    return Report(
      title: '第${_getWeekNumber(weekStart)}周报告',
      date: weekStart,
      recordCount: totalRecords,
      totalDurationSec: totalDuration,
      photoCount: totalPhotos,
      videoCount: dailyReports.fold<int>(0, (sum, r) => sum + r.videoCount),
      averageDuration: totalRecords > 0 ? totalDuration ~/ totalRecords : 0,
      topThingNames: await _getTopThingNames(startOfWeek, endOfWeek, limit: 5),
      topTags: await _getTopTags(startOfWeek, endOfWeek, limit: 5),
      moodAverage: _calculateWeeklyMoodAverage(dailyReports),
      habitsCompleted: habitsCompleted,
      totalHabits: dailyReports.fold<int>(0, (sum, r) => sum + r.totalHabits),
      dailyBreakdown: dailyReports,
    );
  }

  /// 生成月报告
  Future<Report> generateMonthlyReport(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    
    final records = await _getRecordsInRange(startOfMonth, endOfMonth);
    
    final totalDuration = records.fold<int>(0, (sum, r) => sum + (r['duration_sec'] as int? ?? 0));
    
    // 按日期分组统计
    final dailyStats = <DateTime, DailyStat>{};
    for (final record in records) {
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      final date = DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
      dailyStats.putIfAbsent(date, () => DailyStat(date: date, recordCount: 0, totalDuration: 0));
      dailyStats[date] = dailyStats[date]!.copyWith(
        recordCount: dailyStats[date]!.recordCount + 1,
        totalDuration: dailyStats[date]!.totalDuration + (record['duration_sec'] as int? ?? 0),
      );
    }

    return Report(
      title: '$year年$month月报告',
      date: startOfMonth,
      recordCount: records.length,
      totalDurationSec: totalDuration,
      photoCount: records.fold<int>(0, (sum, r) => sum + _countPhotos(r['photo_paths'] as String?)),
      videoCount: records.fold<int>(0, (sum, r) => sum + _countVideos(r['video_paths'] as String?)),
      averageDuration: records.isNotEmpty ? totalDuration ~/ records.length : 0,
      topThingNames: await _getTopThingNames(startOfMonth, endOfMonth, limit: 10),
      topTags: await _getTopTags(startOfMonth, endOfMonth, limit: 10),
      dailyBreakdown: dailyStats.values.map((s) => Report(
        title: '日报告',
        date: s.date,
        recordCount: s.recordCount,
        totalDurationSec: s.totalDuration,
        photoCount: 0,
        videoCount: 0,
        averageDuration: s.recordCount > 0 ? s.totalDuration ~/ s.recordCount : 0,
      )).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecordsInRange(DateTime start, DateTime end) async {
    final db = await _db;
    return db.query(
      'episode_records',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> _getMoodEntriesInRange(DateTime start, DateTime end) async {
    final db = await _db;
    return db.query(
      'mood_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> _getHabitsInRange(DateTime start, DateTime end) async {
    final db = await _db;
    return db.query('habits');
  }

  Future<List<TopItem>> _getTopThingNames(DateTime start, DateTime end, {int limit = 5}) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT tn.name, COUNT(*) as count
      FROM episode_records r
      INNER JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE r.occurred_at >= ? AND r.occurred_at < ?
      GROUP BY tn.id
      ORDER BY count DESC
      LIMIT ?
    ''', [start.toIso8601String(), end.toIso8601String(), limit]);

    return result.map((r) => TopItem(
      name: r['name'] as String,
      count: r['count'] as int,
    )).toList();
  }

  Future<List<TopItem>> _getTopTags(DateTime start, DateTime end, {int limit = 5}) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT t.name, COUNT(*) as count
      FROM episode_records r
      INNER JOIN record_tags rt ON r.id = rt.record_id
      INNER JOIN tags t ON rt.tag_id = t.id
      WHERE r.occurred_at >= ? AND r.occurred_at < ?
      GROUP BY t.id
      ORDER BY count DESC
      LIMIT ?
    ''', [start.toIso8601String(), end.toIso8601String(), limit]);

    return result.map((r) => TopItem(
      name: r['name'] as String,
      count: r['count'] as int,
    )).toList();
  }

  int _countPhotos(String? photoPaths) {
    if (photoPaths == null || photoPaths.isEmpty) return 0;
    try {
      final list = photoPaths.split(',').where((p) => p.isNotEmpty).toList();
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  int _countVideos(String? videoPaths) {
    if (videoPaths == null || videoPaths.isEmpty) return 0;
    try {
      final list = videoPaths.split(',').where((p) => p.isNotEmpty).toList();
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  double _getMoodValue(String mood) {
    switch (mood) {
      case 'veryBad': return 1;
      case 'bad': return 2;
      case 'neutral': return 3;
      case 'good': return 4;
      case 'veryGood': return 5;
      default: return 3;
    }
  }

  double? _calculateWeeklyMoodAverage(List<Report> dailyReports) {
    final moods = dailyReports.where((r) => r.moodAverage != null).map((r) => r.moodAverage!).toList();
    if (moods.isEmpty) return null;
    return moods.fold<double>(0, (sum, m) => sum + m) / moods.length;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return (days / 7).ceil();
  }
}

/// 报告数据模型
class Report {
  final String title;
  final DateTime date;
  final int recordCount;
  final int totalDurationSec;
  final int photoCount;
  final int videoCount;
  final int averageDuration;
  final List<TopItem> topThingNames;
  final List<TopItem> topTags;
  final double? moodAverage;
  final int habitsCompleted;
  final int totalHabits;
  final List<Report>? dailyBreakdown;

  const Report({
    required this.title,
    required this.date,
    required this.recordCount,
    required this.totalDurationSec,
    required this.photoCount,
    required this.videoCount,
    required this.averageDuration,
    this.topThingNames = const [],
    this.topTags = const [],
    this.moodAverage,
    this.habitsCompleted = 0,
    this.totalHabits = 0,
    this.dailyBreakdown,
  });

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('═' * 50);
    buffer.writeln('  $title');
    buffer.writeln('═' * 50);
    buffer.writeln();
    buffer.writeln('📊 统计概览');
    buffer.writeln('─' * 30);
    buffer.writeln('  记录数量: $recordCount');
    buffer.writeln('  总时长: ${_formatDuration(totalDurationSec)}');
    buffer.writeln('  平均时长: ${_formatDuration(averageDuration)}');
    buffer.writeln('  照片数: $photoCount');
    buffer.writeln('  视频数: $videoCount');
    buffer.writeln();

    if (topThingNames.isNotEmpty) {
      buffer.writeln('🏷️ 最常用事情');
      buffer.writeln('─' * 30);
      for (var i = 0; i < topThingNames.length; i++) {
        buffer.writeln('  ${i + 1}. ${topThingNames[i].name} (${topThingNames[i].count}次)');
      }
      buffer.writeln();
    }

    if (topTags.isNotEmpty) {
      buffer.writeln('🏷️ 最常用标签');
      buffer.writeln('─' * 30);
      for (var i = 0; i < topTags.length; i++) {
        buffer.writeln('  ${i + 1}. ${topTags[i].name} (${topTags[i].count}次)');
      }
      buffer.writeln();
    }

    if (moodAverage != null) {
      buffer.writeln('😊 平均情绪: ${moodAverage!.toStringAsFixed(1)}/5');
      buffer.writeln();
    }

    if (habitsCompleted > 0 || totalHabits > 0) {
      buffer.writeln('🎯 习惯完成: $habitsCompleted/$totalHabits');
      buffer.writeln();
    }

    buffer.writeln('═' * 50);
    return buffer.toString();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
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

/// 每日统计
class DailyStat {
  final DateTime date;
  final int recordCount;
  final int totalDuration;

  const DailyStat({
    required this.date,
    required this.recordCount,
    required this.totalDuration,
  });

  DailyStat copyWith({int? recordCount, int? totalDuration}) {
    return DailyStat(
      date: date,
      recordCount: recordCount ?? this.recordCount,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

final reportServiceProvider = Provider<ReportService>((ref) {
    final dbAsync = ref.watch(databaseProvider);
    return ReportService(dbAsync);
});