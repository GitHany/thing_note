import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 每日摘要数据模型
class DailySummary {
  final DateTime date;
  final int totalRecords;
  final int totalDurationSec;
  final int photoCount;
  final int audioCount;
  final int videoCount;
  final int favoriteCount;
  final List<TopThingName> topThingNames;
  final List<String> highlights;
  final DateTime generatedAt;

  DailySummary({
    required this.date,
    required this.totalRecords,
    required this.totalDurationSec,
    required this.photoCount,
    required this.audioCount,
    required this.videoCount,
    required this.favoriteCount,
    required this.topThingNames,
    required this.highlights,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalRecords': totalRecords,
        'totalDurationSec': totalDurationSec,
        'photoCount': photoCount,
        'audioCount': audioCount,
        'videoCount': videoCount,
        'favoriteCount': favoriteCount,
        'topThingNames': topThingNames.map((t) => t.toJson()).toList(),
        'highlights': highlights,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date'] as String),
      totalRecords: json['totalRecords'] as int,
      totalDurationSec: json['totalDurationSec'] as int,
      photoCount: json['photoCount'] as int,
      audioCount: json['audioCount'] as int,
      videoCount: json['videoCount'] as int,
      favoriteCount: json['favoriteCount'] as int,
      topThingNames: (json['topThingNames'] as List)
          .map((t) => TopThingName.fromJson(t as Map<String, dynamic>))
          .toList(),
      highlights: (json['highlights'] as List).cast<String>(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  /// 生成摘要文本
  String toText({String? language}) {
    final isZh = language == 'zh' || (language == null && !kIsWeb);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();

    if (isZh) {
      buffer.writeln('📅 $dateStr 每日摘要');
      buffer.writeln('');
      buffer.writeln('📊 今日数据');
      buffer.writeln('• 记录总数: $totalRecords');
      if (totalDurationSec > 0) {
        buffer.writeln('• 总时长: ${_formatDuration(totalDurationSec, isZh)}');
      }
      buffer.writeln('• 📷 $photoCount | 🎵 $audioCount | 🎬 $videoCount');
      if (favoriteCount > 0) {
        buffer.writeln('• ⭐ 收藏 $favoriteCount 条');
      }

      if (topThingNames.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('🏆 热门事项');
        for (final thing in topThingNames.take(3)) {
          buffer.writeln('• ${thing.name}: ${thing.count}条');
        }
      }

      if (highlights.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('✨ 亮点');
        for (final highlight in highlights) {
          buffer.writeln('• $highlight');
        }
      }
    } else {
      buffer.writeln('📅 Daily Summary - $dateStr');
      buffer.writeln('');
      buffer.writeln('📊 Today\'s Stats');
      buffer.writeln('• Total Records: $totalRecords');
      if (totalDurationSec > 0) {
        buffer.writeln('• Total Duration: ${_formatDuration(totalDurationSec, isZh)}');
      }
      buffer.writeln('• 📷 $photoCount | 🎵 $audioCount | 🎬 $videoCount');
      if (favoriteCount > 0) {
        buffer.writeln('• ⭐ $favoriteCount favorites');
      }

      if (topThingNames.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('🏆 Top Activities');
        for (final thing in topThingNames.take(3)) {
          buffer.writeln('• ${thing.name}: ${thing.count} records');
        }
      }

      if (highlights.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('✨ Highlights');
        for (final highlight in highlights) {
          buffer.writeln('• $highlight');
        }
      }
    }

    return buffer.toString();
  }

  String _formatDuration(int seconds, bool isZh) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final mins = seconds ~/ 60;
      return isZh ? '$mins分钟' : '${mins}m';
    }
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return isZh ? '$hours小时$mins分钟' : '$hours h $mins m';
  }
}

/// 热门事项
class TopThingName {
  final int? id;
  final String name;
  final int count;

  TopThingName({
    this.id,
    required this.name,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'count': count,
      };

  factory TopThingName.fromJson(Map<String, dynamic> json) {
    return TopThingName(
      id: json['id'] as int?,
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

/// 每日摘要服务
class DailySummaryService {
  static const _keySummaryPrefix = 'daily_summary_';
  static const _keyLastPushDate = 'last_summary_push_date';
  static const _keyEnabled = 'daily_summary_enabled';

  /// 生成指定日期的摘要
  Future<DailySummary> generateSummary(
    List<EpisodeRecord> records,
    DateTime date,
  ) async {
    // 筛选当天的记录
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final dayRecords = records.where((r) =>
        r.occurredAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
        r.occurredAt.isBefore(endOfDay)).toList();

    // 统计数据
    final totalRecords = dayRecords.length;
    final totalDuration = dayRecords.fold<int>(0, (sum, r) => sum + r.durationSec);
    final photoCount = dayRecords.fold<int>(0, (sum, r) => sum + r.photoPaths.length);
    final audioCount = dayRecords.fold<int>(0, (sum, r) => sum + r.audioPaths.length);
    final videoCount = dayRecords.fold<int>(0, (sum, r) => sum + r.videoPaths.length);
    final favoriteCount = dayRecords.where((r) => r.isFavorite).length;

    // 统计热门事项
    final thingNameCounts = <int?, Map<String, dynamic>>{};
    for (final record in dayRecords) {
      if (!thingNameCounts.containsKey(record.thingNameId)) {
        thingNameCounts[record.thingNameId] = {'id': record.thingNameId, 'name': 'Record', 'count': 0};
      }
      thingNameCounts[record.thingNameId]!['count']++;
    }

    final topThingNames = thingNameCounts.entries
        .map((e) => TopThingName(
              id: e.value['id'] as int?,
              name: e.value['name'] as String,
              count: e.value['count'] as int,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // 生成亮点
    final highlights = <String>[];
    if (totalRecords >= 10) {
      highlights.add(totalRecords >= 20 ? 'Very productive day!' : 'Great productivity!');
    }
    if (photoCount >= 5) {
      highlights.add('Captured $photoCount photos');
    }
    if (favoriteCount >= 3) {
      highlights.add('Marked $favoriteCount favorites');
    }
    if (totalDuration > 3600 * 2) {
      highlights.add('Spent over 2 hours recording');
    }

    return DailySummary(
      date: date,
      totalRecords: totalRecords,
      totalDurationSec: totalDuration,
      photoCount: photoCount,
      audioCount: audioCount,
      videoCount: videoCount,
      favoriteCount: favoriteCount,
      topThingNames: topThingNames.take(5).toList(),
      highlights: highlights,
      generatedAt: DateTime.now(),
    );
  }

  /// 保存摘要
  Future<void> saveSummary(DailySummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySummaryPrefix${summary.date.year}_${summary.date.month}_${summary.date.day}';
    await prefs.setString(key, jsonEncode(summary.toJson()));
  }

  /// 获取指定日期的摘要
  Future<DailySummary?> getSummary(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keySummaryPrefix${date.year}_${date.month}_${date.day}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      return DailySummary.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 获取最近N天的摘要
  Future<List<DailySummary>> getRecentSummaries(int days) async {
    final summaries = <DailySummary>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final summary = await getSummary(date);
      if (summary != null) {
        summaries.add(summary);
      }
    }

    return summaries;
  }

  /// 设置是否启用每日推送
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  /// 检查是否启用
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  /// 设置上次推送日期
  Future<void> setLastPushDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastPushDate, date.toIso8601String());
  }

  /// 获取上次推送日期
  Future<DateTime?> getLastPushDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastPushDate);
    if (str == null) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }

  /// 检查今天是否已推送
  Future<bool> isPushNeeded() async {
    final lastPush = await getLastPushDate();
    if (lastPush == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPushDay = DateTime(lastPush.year, lastPush.month, lastPush.day);

    return lastPushDay.isBefore(today);
  }
}