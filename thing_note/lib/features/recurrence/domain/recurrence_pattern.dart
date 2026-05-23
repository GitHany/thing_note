import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 记录重复模式
class RecordRecurrencePattern {
  final int? thingNameId;
  final String? thingName;
  final int dayOfWeek; // 1-7 (周一到周日)
  final int suggestedHour;
  final int suggestedMinute;
  final double confidence;
  final String repeatType; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final List<int> occurrenceDays; // 每月几号 (用于monthly)

  RecordRecurrencePattern({
    this.thingNameId,
    this.thingName,
    required this.dayOfWeek,
    required this.suggestedHour,
    required this.suggestedMinute,
    this.confidence = 0.0,
    this.repeatType = 'none',
    this.occurrenceDays = const [],
  });

  Map<String, dynamic> toJson() => {
        'thingNameId': thingNameId,
        'thingName': thingName,
        'dayOfWeek': dayOfWeek,
        'suggestedHour': suggestedHour,
        'suggestedMinute': suggestedMinute,
        'confidence': confidence,
        'repeatType': repeatType,
        'occurrenceDays': occurrenceDays,
      };

  factory RecordRecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecordRecurrencePattern(
      thingNameId: json['thingNameId'] as int?,
      thingName: json['thingName'] as String?,
      dayOfWeek: json['dayOfWeek'] as int? ?? 1,
      suggestedHour: json['suggestedHour'] as int? ?? 9,
      suggestedMinute: json['suggestedMinute'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      repeatType: json['repeatType'] as String? ?? 'none',
      occurrenceDays: (json['occurrenceDays'] as List?)?.cast<int>() ?? [],
    );
  }

  RecordRecurrencePattern copyWith({
    int? thingNameId,
    String? thingName,
    int? dayOfWeek,
    int? suggestedHour,
    int? suggestedMinute,
    double? confidence,
    String? repeatType,
    List<int>? occurrenceDays,
  }) {
    return RecordRecurrencePattern(
      thingNameId: thingNameId ?? this.thingNameId,
      thingName: thingName ?? this.thingName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      suggestedHour: suggestedHour ?? this.suggestedHour,
      suggestedMinute: suggestedMinute ?? this.suggestedMinute,
      confidence: confidence ?? this.confidence,
      repeatType: repeatType ?? this.repeatType,
      occurrenceDays: occurrenceDays ?? this.occurrenceDays,
    );
  }
}

/// 重复模式分析器
class RecurrenceAnalyzer {
  /// 分析记录的重复模式
  /// 分析至少3条同一thingName的记录来检测模式
  static RecordRecurrencePattern? analyzePatterns(
    List<DateTime> occurrenceDates,
    int? thingNameId,
    String? thingName,
  ) {
    if (occurrenceDates.length < 3) return null;

    // 按日期排序
    final sortedDates = List<DateTime>.from(occurrenceDates)
      ..sort((a, b) => a.compareTo(b));

    // 计算间隔天数
    final List<int> gaps = [];
    for (int i = 1; i < sortedDates.length; i++) {
      final gap = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      gaps.add(gap);
    }

    // 计算平均间隔
    final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;

    // 分析重复类型
    String repeatType = 'none';
    double confidence = 0.0;

    // 每日重复（间隔约1天）
    if (avgGap >= 0.9 && avgGap <= 1.1) {
      repeatType = 'daily';
      confidence = _calculateConfidence(gaps, 1.0);
    }
    // 每周重复（间隔约7天）
    else if (avgGap >= 6.5 && avgGap <= 7.5) {
      repeatType = 'weekly';
      confidence = _calculateConfidence(gaps, 7.0);
    }
    // 双周重复（间隔约14天）
    else if (avgGap >= 13.5 && avgGap <= 14.5) {
      repeatType = 'biweekly';
      confidence = _calculateConfidence(gaps, 14.0);
    }
    // 每月重复（间隔约30天）
    else if (avgGap >= 28.0 && avgGap <= 32.0) {
      repeatType = 'monthly';
      confidence = _calculateConfidence(gaps, 30.0);
    }
    // 每季度（间隔约90天）
    else if (avgGap >= 85.0 && avgGap <= 95.0) {
      repeatType = 'quarterly';
      confidence = _calculateConfidence(gaps, 90.0);
    }
    // 每年（间隔约365天）
    else if (avgGap >= 360.0 && avgGap <= 370.0) {
      repeatType = 'yearly';
      confidence = _calculateConfidence(gaps, 365.0);
    }

    if (repeatType == 'none' || confidence < 0.5) return null;

    // 获取最常见的星期几
    final dayOfWeekCounts = <int, int>{};
    for (final date in sortedDates) {
      final dow = date.weekday;
      dayOfWeekCounts[dow] = (dayOfWeekCounts[dow] ?? 0) + 1;
    }
    final mostCommonDow = dayOfWeekCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 获取最常见的时间
    final hourCounts = <int, int>{};
    final minuteCounts = <int, int>{};
    for (final date in sortedDates) {
      hourCounts[date.hour] = (hourCounts[date.hour] ?? 0) + 1;
      final minuteSlot = (date.minute ~/ 15) * 15; // 按15分钟分组
      minuteCounts[minuteSlot] = (minuteCounts[minuteSlot] ?? 0) + 1;
    }
    final mostCommonHour = hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final mostCommonMinute = minuteCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 分析每月几号（用于monthly模式）
    List<int> occurrenceDays = [];
    if (repeatType == 'monthly' || repeatType == 'yearly') {
      final dayCounts = <int, int>{};
      for (final date in sortedDates) {
        dayCounts[date.day] = (dayCounts[date.day] ?? 0) + 1;
      }
      final sortedDays = dayCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      occurrenceDays = sortedDays.take(3).map((e) => e.key).toList();
    }

    return RecordRecurrencePattern(
      thingNameId: thingNameId,
      thingName: thingName,
      dayOfWeek: mostCommonDow,
      suggestedHour: mostCommonHour,
      suggestedMinute: mostCommonMinute,
      confidence: confidence,
      repeatType: repeatType,
      occurrenceDays: occurrenceDays,
    );
  }

  /// 计算置信度（基于间隔的标准差）
  static double _calculateConfidence(List<int> gaps, double expectedGap) {
    if (gaps.isEmpty) return 0.0;

    final variance = gaps.map((g) => (g - expectedGap).abs()).reduce((a, b) => a + b) / gaps.length;

    // 间隔越接近预期，置信度越高
    final deviationScore = 1.0 - (variance / expectedGap).clamp(0.0, 1.0);
    return deviationScore;
  }

  /// 根据模式预测下次发生时间
  static DateTime? predictNextOccurrence(RecordRecurrencePattern pattern) {
    final now = DateTime.now();
    DateTime next;

    switch (pattern.repeatType) {
      case 'daily':
        next = DateTime(now.year, now.month, now.day, pattern.suggestedHour, pattern.suggestedMinute);
        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case 'weekly':
        next = _nextWeekday(now, pattern.dayOfWeek, pattern.suggestedHour, pattern.suggestedMinute);
        break;
      case 'biweekly':
        next = _nextWeekday(now, pattern.dayOfWeek, pattern.suggestedHour, pattern.suggestedMinute);
        break;
      case 'monthly':
        next = _nextMonthlyDay(now, pattern.occurrenceDays, pattern.suggestedHour, pattern.suggestedMinute);
        break;
      case 'yearly':
        next = DateTime(now.year, 1, 1, pattern.suggestedHour, pattern.suggestedMinute);
        if (next.isBefore(now)) {
          next = DateTime(now.year + 1, 1, 1, pattern.suggestedHour, pattern.suggestedMinute);
        }
        break;
      default:
        return null;
    }

    return next;
  }

  static DateTime _nextWeekday(DateTime from, int dayOfWeek, int hour, int minute) {
    final currentDow = from.weekday;
    int daysUntil = dayOfWeek - currentDow;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      final targetTime = DateTime(from.year, from.month, from.day, hour, minute);
      if (targetTime.isBefore(from)) {
        daysUntil = 7;
      }
    }
    return DateTime(from.year, from.month, from.day + daysUntil, hour, minute);
  }

  static DateTime _nextMonthlyDay(DateTime from, List<int> days, int hour, int minute) {
    if (days.isEmpty) {
      return _nextWeekday(from, from.weekday, hour, minute);
    }

    for (final day in days..sort()) {
      try {
        final target = DateTime(from.year, from.month, day, hour, minute);
        if (target.isAfter(from)) {
          return target;
        }
      } catch (_) {
        // 某些月份可能没有这一天（如31号）
        continue;
      }
    }

    // 下个月
    final nextMonth = DateTime(from.year, from.month + 1, days.first, hour, minute);
    return nextMonth;
  }
}

/// 重复模式存储
class RecurrencePatternRepository {
  static const _keyPatterns = 'recurrence_patterns';

  Future<List<RecordRecurrencePattern>> getSavedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyPatterns);
      if (jsonStr == null) return [];

      final list = jsonDecode(jsonStr) as List;
      return list.map((map) => RecordRecurrencePattern.fromJson(map as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePatterns(List<RecordRecurrencePattern> patterns) async {
    final prefs = await SharedPreferences.getInstance();
    final list = patterns.map((p) => p.toJson()).toList();
    await prefs.setString(_keyPatterns, jsonEncode(list));
  }

  Future<void> savePattern(RecordRecurrencePattern pattern) async {
    final patterns = await getSavedPatterns();
    // 替换同一 thingName 的模式
    patterns.removeWhere((p) => p.thingNameId == pattern.thingNameId);
    patterns.add(pattern);
    await savePatterns(patterns);
  }

  Future<void> clearPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatterns);
  }

  Future<RecordRecurrencePattern?> getPatternForThingName(int thingNameId) async {
    final patterns = await getSavedPatterns();
    try {
      return patterns.firstWhere((p) => p.thingNameId == thingNameId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePattern(int thingNameId) async {
    final patterns = await getSavedPatterns();
    patterns.removeWhere((p) => p.thingNameId == thingNameId);
    await savePatterns(patterns);
  }
}