/// 时间洞察报告 - Time Insight Report
/// 深度分析用户的时间使用模式
library;

/// 时间洞察模型
class TimeInsightReport {
  final DateTime generatedAt;
  final TimePeriod period;
  final TimeDistribution distribution;
  final List<TimePattern> patterns;
  final List<ActivityInsight> insights;
  final ComparisonReport? comparison;

  TimeInsightReport({
    required this.generatedAt,
    required this.period,
    required this.distribution,
    required this.patterns,
    required this.insights,
    this.comparison,
  });
}

/// 时间周期
enum TimePeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
}

/// 时间分布
class TimeDistribution {
  final Map<String, int> hourDistribution; // hour -> minutes
  final Map<String, int> dayDistribution; // dayOfWeek -> minutes
  final Map<String, int> tagDistribution; // tag -> count
  final Map<String, int> thingNameDistribution; // thingName -> count

  TimeDistribution({
    this.hourDistribution = const {},
    this.dayDistribution = const {},
    this.tagDistribution = const {},
    this.thingNameDistribution = const {},
  });
}

/// 时间模式
class TimePattern {
  final String name;
  final String description;
  final double confidence; // 0.0 - 1.0
  final PatternType type;
  final List<String> evidence;

  TimePattern({
    required this.name,
    required this.description,
    required this.confidence,
    required this.type,
    this.evidence = const [],
  });
}

/// 模式类型
enum PatternType {
  morningPerson, // 早起型
  nightOwl, // 夜猫子型
  weekEndActive, // 周末活跃型
  weekdayFocused, // 工作日专注型
  frequentBreaker, // 频繁打断型
  longSessionLover, // 长时间型
}

/// 活动洞察
class ActivityInsight {
  final String category;
  final String title;
  final String description;
  final InsightType type;
  final String? suggestion;

  ActivityInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.type,
    this.suggestion,
  });
}

/// 洞察类型
enum InsightType {
  highlight, // 亮点
  improvement, // 改进建议
  alert, // 警示
  achievement, // 成就
}

/// 对比报告
class ComparisonReport {
  final TimePeriod comparedPeriod;
  final int totalRecordsChange; // 变化量
  final double totalRecordsChangePercent;
  final int totalMinutesChange;
  final Map<String, int> tagChanges;
  final Map<String, int> thingNameChanges;

  ComparisonReport({
    required this.comparedPeriod,
    required this.totalRecordsChange,
    required this.totalRecordsChangePercent,
    required this.totalMinutesChange,
    this.tagChanges = const {},
    this.thingNameChanges = const {},
  });
}

/// 周对比数据
class WeeklyComparison {
  final int thisWeekRecords;
  final int lastWeekRecords;
  final int thisWeekMinutes;
  final int lastWeekMinutes;
  final double recordChangePercent;
  final double minuteChangePercent;

  WeeklyComparison({
    required this.thisWeekRecords,
    required this.lastWeekRecords,
    required this.thisWeekMinutes,
    required this.lastWeekMinutes,
    required this.recordChangePercent,
    required this.minuteChangePercent,
  });
}