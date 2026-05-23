import 'package:thing_note/features/record/domain/episode_record.dart';

class ReminderPattern {
  final int? thingNameId;
  final String? thingName;
  final int? dayOfWeek; // 1-7, null 表示所有天
  final int? suggestedHour;
  final int? suggestedMinute;
  final double confidence; // 0-1

  const ReminderPattern({
    this.thingNameId,
    this.thingName,
    this.dayOfWeek,
    this.suggestedHour,
    this.suggestedMinute,
    this.confidence = 0.0,
  });

  String get suggestedTimeString {
    if (suggestedHour == null) return '--:--';
    final hour = suggestedHour!.toString().padLeft(2, '0');
    final minute = (suggestedMinute ?? 0).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ReminderAnalyzer {
  /// 分析记录历史，生成提醒模式
  List<ReminderPattern> analyzePatterns(List<EpisodeRecord> records) {
    if (records.isEmpty) return [];

    // 按 thingNameId 分组
    final byThing = <int?, List<EpisodeRecord>>{};
    for (final record in records) {
      byThing.putIfAbsent(record.thingNameId, () => []).add(record);
    }

    final patterns = <ReminderPattern>[];
    for (final entry in byThing.entries) {
      final thingPatterns = _analyzeForThing(entry.key, entry.value);
      patterns.addAll(thingPatterns);
    }

    // 按置信度排序
    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));

    return patterns;
  }

  List<ReminderPattern> _analyzeForThing(int? thingNameId, List<EpisodeRecord> records) {
    // 至少需要 3 条记录才能分析模式
    if (records.length < 3) return [];

    // 分析最常记录的时间段
    final hourCounts = <int, int>{};
    final dayOfWeekCounts = <int, int>{};

    for (final record in records) {
      final hour = record.occurredAt.hour;
      final dayOfWeek = record.occurredAt.weekday;

      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
    }

    final patterns = <ReminderPattern>[];

    // 找到最频繁的小时
    int? mostFrequentHour;
    int maxHourCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxHourCount) {
        maxHourCount = count;
        mostFrequentHour = hour;
      }
    });

    if (mostFrequentHour != null && maxHourCount >= 3) {
      patterns.add(ReminderPattern(
        thingNameId: thingNameId,
        suggestedHour: mostFrequentHour,
        suggestedMinute: 0,
        confidence: maxHourCount / records.length,
      ));
    }

    // 分析星期模式
    int? mostFrequentDay;
    int maxDayCount = 0;
    dayOfWeekCounts.forEach((day, count) {
      if (count > maxDayCount) {
        maxDayCount = count;
        mostFrequentDay = day;
      }
    });

    if (mostFrequentDay != null && maxDayCount >= 3 && patterns.isNotEmpty) {
      // 更新现有模式添加星期信息
      patterns[0] = ReminderPattern(
        thingNameId: patterns[0].thingNameId,
        dayOfWeek: mostFrequentDay,
        suggestedHour: patterns[0].suggestedHour,
        suggestedMinute: patterns[0].suggestedMinute,
        confidence: (patterns[0].confidence + (maxDayCount / records.length)) / 2,
      );
    }

    return patterns;
  }
}