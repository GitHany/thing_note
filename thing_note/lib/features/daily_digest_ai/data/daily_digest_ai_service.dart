import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'daily_digest_ai_repository.dart';
import '../domain/daily_digest_ai.dart';

final dailyDigestAIServiceProvider = Provider<DailyDigestAIService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyDigestAIService(dbAsync);
});

class DailyDigestAIService {
  final DailyDigestAIRepository _repository;

  DailyDigestAIService(AsyncValue<Database> dbAsync)
      : _repository = DailyDigestAIRepository(dbAsync);

  // 生成每日摘要
  Future<DailyDigestAI> generateDailyDigest(String date) async {
    // 获取当日记录
    final records = await _getRecordsForDate(date);
    final recordsCount = records.length;
    final totalMinutes = records.fold<int>(0, (sum, r) => sum + (r['duration_sec'] as int? ?? 0) ~/ 60);

    // 获取最常用的事情名称
    final thingNameCounts = <String, int>{};
    for (final record in records) {
      final thingNameId = record['thing_name_id'] as int?;
      if (thingNameId != null) {
        // 这里需要查询 thing_names 表获取名称
        final name = await _getThingNameById(thingNameId);
        if (name != null) {
          thingNameCounts[name] = (thingNameCounts[name] ?? 0) + 1;
        }
      }
    }
    final topThingName = thingNameCounts.entries.isNotEmpty
        ? thingNameCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    // 获取标签统计
    final tagCounts = <String, int>{};
    for (final record in records) {
      final annotations = record['annotations'] as String?;
      if (annotations != null && annotations.isNotEmpty) {
        // 解析 annotations JSON 获取标签
        // 这里简化处理，实际需要解析 JSON
      }
    }

    // 计算连续记录天数
    final streakDays = await _calculateStreak(date);

    // 生成摘要内容
    final summary = _generateSummary(recordsCount, totalMinutes, topThingName);
    final highlights = _generateHighlights(records);
    final patterns = _identifyPatterns(records);
    final suggestions = _generateSuggestions(records, streakDays);
    final weeklyComparison = await _getWeeklyComparison(date);

    final digest = DailyDigestAI(
      date: date,
      summary: summary,
      highlights: highlights,
      patterns: patterns,
      insight: _generateInsight(records, patterns),
      recordCount: recordsCount,
      totalMinutes: totalMinutes,
      moodAverage: await _getAverageMood(date),
      topThingName: topThingName,
      topTags: tagCounts.keys.take(5).toList(),
      suggestions: suggestions,
      weeklyComparison: weeklyComparison,
      streakDays: streakDays,
      createdAt: DateTime.now().toIso8601String(),
    );

    // 保存摘要
    await _repository.saveDailyDigest(digest);
    return digest;
  }

  Future<List<Map<String, dynamic>>> _getRecordsForDate(String date) async {
    // 模拟获取记录，实际需要从数据库查询
    return [];
  }

  Future<String?> _getThingNameById(int id) async {
    // 实际实现需要查询数据库
    return null;
  }

  Future<int> _calculateStreak(String currentDate) async {
    int streak = 0;
    DateTime date = DateTime.parse(currentDate);
    
    while (true) {
      final dateStr = date.toIso8601String().split('T')[0];
      final records = await _getRecordsForDate(dateStr);
      if (records.isNotEmpty) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<double?> _getAverageMood(String date) async {
    // 从 mood 相关表获取平均情绪
    return null;
  }

  String _generateSummary(int recordCount, int totalMinutes, String? topThing) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final timeStr = hours > 0 ? '$hours小时$minutes分钟' : '$minutes分钟';
    
    String summary = '今日共记录 $recordCount 条事件，总时长 $timeStr。';
    if (topThing != null) {
      summary += '最常做的事情是「$topThing」。';
    }
    return summary;
  }

  List<String> _generateHighlights(List<Map<String, dynamic>> records) {
    final highlights = <String>[];
    
    if (records.length >= 5) {
      highlights.add('🎯 今天记录很充实！');
    }
    
    // 检查是否有长时间记录
    for (final record in records) {
      final duration = record['duration_sec'] as int? ?? 0;
      if (duration >= 3600) {
        highlights.add('⏱️ 有一个超过1小时的记录');
        break;
      }
    }
    
    return highlights;
  }

  List<String> _identifyPatterns(List<Map<String, dynamic>> records) {
    final patterns = <String>[];
    
    // 分析时间分布
    final hourCounts = <int, int>{};
    for (final record in records) {
      final occurredAt = record['occurred_at'] as String?;
      if (occurredAt != null) {
        final hour = DateTime.parse(occurredAt).hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }
    
    if (hourCounts.isNotEmpty) {
      final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      if (peakHour >= 6 && peakHour <= 12) {
        patterns.add('🌅 你是一个早起型的人');
      } else if (peakHour >= 18 && peakHour <= 22) {
        patterns.add('🌙 你更倾向于晚间活动');
      }
    }
    
    return patterns;
  }

  List<String> _generateSuggestions(List<Map<String, dynamic>> records, int streak) {
    final suggestions = <String>[];
    
    if (streak > 7) {
      suggestions.add('🔥 连续记录 $streak 天了！保持这个好习惯！');
    }
    
    if (records.isEmpty) {
      suggestions.add('📝 今天还没有记录，试着记录一件事吧！');
    } else if (records.length < 3) {
      suggestions.add('💡 可以尝试每天记录 3-5 件事，效果会更好');
    }
    
    return suggestions;
  }

  String _generateInsight(List<Map<String, dynamic>> records, List<String> patterns) {
    if (patterns.isEmpty) return '';
    
    final insight = StringBuffer('根据今日数据：\n');
    for (final pattern in patterns) {
      insight.write('- $pattern\n');
    }
    return insight.toString();
  }

  Future<String?> _getWeeklyComparison(String date) async {
    final currentDate = DateTime.parse(date);
    final weekStart = currentDate.subtract(const Duration(days: 7));
    
    final thisWeekRecords = await _getRecordsForDate(date);
    final lastWeekRecords = await _getRecordsForDate(weekStart.toIso8601String().split('T')[0]);
    
    if (thisWeekRecords.length > lastWeekRecords.length) {
      return '比上周多了 ${thisWeekRecords.length - lastWeekRecords.length} 条记录，继续保持！';
    } else if (thisWeekRecords.length < lastWeekRecords.length) {
      return '比上周少了 ${lastWeekRecords.length - thisWeekRecords.length} 条记录，明天加油！';
    }
    return '和上周记录数持平';
  }

  // 获取配置
  Future<DigestConfig> getConfig() async {
    return await _repository.getConfig();
  }

  // 保存配置
  Future<void> saveConfig(DigestConfig config) async {
    await _repository.saveConfig(config);
  }

  // 生成每周摘要
  Future<WeeklyDigest> generateWeeklyDigest(int weekNumber, int year) async {
    final weekRecords = <Map<String, dynamic>>[];
    final startDate = _getWeekStartDate(weekNumber, year);
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final records = await _getRecordsForDate(date.toIso8601String().split('T')[0]);
      weekRecords.addAll(records);
    }
    
    final totalMinutes = weekRecords.fold<int>(0, (sum, r) => sum + (r['duration_sec'] as int? ?? 0) ~/ 60);
    
    return WeeklyDigest(
      weekNumber: weekNumber,
      year: year,
      summary: '本周共记录 ${weekRecords.length} 条事件，总时长 ${totalMinutes ~/ 60} 小时',
      highlights: _generateHighlights(weekRecords),
      activityBreakdown: {},
      totalRecords: weekRecords.length,
      totalMinutes: totalMinutes,
      patterns: _identifyPatterns(weekRecords),
      insight: _generateInsight(weekRecords, []),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  DateTime _getWeekStartDate(int weekNumber, int year) {
    final jan1 = DateTime(year, 1, 1);
    final daysOffset = (weekNumber - 1) * 7;
    return jan1.add(Duration(days: daysOffset - jan1.weekday + 1));
  }

  // 获取每日摘要
  Future<DailyDigestAI?> getDailyDigest(String date) async {
    return await _repository.getDailyDigest(date);
  }

  // 获取最近的摘要
  Future<List<DailyDigestAI>> getRecentDigests(int limit) async {
    return await _repository.getRecentDigests(limit);
  }
}